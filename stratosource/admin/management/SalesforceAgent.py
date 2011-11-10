#    Copyright 2010, 2011 Red Hat Inc.
#
#    This file is part of StratoSource.
#
#    StratoSource is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    StratoSource is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with StratoSource.  If not, see <http://www.gnu.org/licenses/>.
#    

from suds.client import Client
import suds
import binascii
import time
import logging
import httplib, urllib
import json
from urlparse import urlparse

__author__="mark"
__date__ ="$Aug 15, 2010 9:48:38 PM$"

_API_VERSION = 23.0
_DEFAULT_LOGNAME = '/tmp/agent.log'
_METADATA_TIMEOUT=60 * 80
_METADATA_POLL_SLEEP=10
_DEPLOY_TIMEOUT=60 * 10
_DEPLOY_POLL_SLEEP=10


class LoginError(Exception):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)



class SalesforceAgent:

    def __init__(self, partner_wsdl_url, metadata_wsdl_url = None):
        logging.basicConfig(level=logging.INFO)
        #logging.getLogger('suds.client').setLevel(logging.INFO)
        self.logname = _DEFAULT_LOGNAME
        self.logger = logging.getLogger(__file__)
        self.login_result = None
        if metadata_wsdl_url:
            self.meta = Client(metadata_wsdl_url)
        else:
            self.meta = None
        self.partner = Client(partner_wsdl_url)

    def set_logname(self, name):
        self.logname = name
        logging.basicConfig(filename=name,level=logging.DEBUG)
        self.logger = logging.getLogger(__file__)

    def getSessionId(self):
        return self.sid.sessionId
        
    def getServerLocation(self):
        return urlparse(self.login_result.serverUrl).netloc

    def login(self, user, password, server_url = None):
        if server_url: self.partner.set_options(location=server_url)
        try:
            self.login_result = self.partner.service.login(user, password)
        except suds.WebFault as sf:
            raise LoginError(str(sf))
        self.sid = self.partner.factory.create('SessionHeader')
        self.sid.sessionId = self.login_result.sessionId
        self.partner.set_options(soapheaders=self.sid)
        self.partner.set_options(location=self.login_result.serverUrl)

        self.meta.set_options(soapheaders=self.sid)
        self.meta.set_options(location=self.login_result.metadataServerUrl)

    def close(self):
        if not self.login_result:
            raise Exception('Initialization error: not logged in')
	#
	# try to avoid timeouts by not logging out, which invalidates shared session of other
 	# jobs using the same salesforce api credentials.
	#
#        self.partner.service.logout()
        self.login_result = None

    def _buildCustomObjectsPackage(self):
        self.logger.debug('loading Salesforce catalog for custom field discovery')
        query = self.meta.factory.create('ListMetadataQuery')
        query.type = 'CustomObject'
        props = self.meta.service.listMetadata([query], _API_VERSION)
        self.logger.debug('catalog contains %d objects' % len(props))
        ptm = self.meta.factory.create('PackageTypeMembers')
        ptm.name = 'CustomObject'
        ptm.members = [prop.fullName for prop in props]
        return ptm

    def retrieve_userchanges(self):
        classes = {}
        triggers = {}
        pages = {}
        self.rest_headers = {"Authorization": "OAuth %s" % self.getSessionId(), "Content-Type": "application/json" }
        serverloc = self.getServerLocation()
        serverloc = 'cs4.salesforce.com'; ####### !!!! FIX THIS !!!!!!

        rest_conn = httplib.HTTPSConnection(serverloc)
        classes = self._getChangesMap(rest_conn, 'ApexClass')
        for clazz in classes: clazz['Name'] += '.cls'
        triggers = self._getChangesMap(rest_conn, 'ApexTrigger')
        for trigger in triggers: trigger['Name'] += '.trigger'
        pages = self._getChangesMap(rest_conn, 'ApexPage', withstatus=False)
        for page in pages: page['Name'] += '.page'
        rest_conn.close()
        return (classes, triggers, pages)

    def _getChangesMap(self, rest_conn, sfobject, withstatus=True):
        if withstatus:
            params = urllib.urlencode({'q': "select Id, Name, LastModifiedById, LastModifiedBy.Name, LastModifiedDate from %s where Status = 'Active' and NamespacePrefix = '' order by name" % sfobject})
        else:
            params = urllib.urlencode({'q': "select Id, Name, LastModifiedById, LastModifiedBy.Name, LastModifiedDate from %s where NamespacePrefix = '' order by name" % sfobject})
        data = self._invokeGetREST(rest_conn, "query/?%s" % params)
        if not data == None:
            return data['records']
        return None

    def _invokePostREST(self, rest_conn, url, payload):
        rest_conn.request("POST", '/services/data/v%s/%s' % (_API_VERSION, url), payload, headers=self.rest_headers)
        response = rest_conn.getresponse()
        resultPayload = response.read()
        if response.status != 201:
            print response.status, response.reason
            return None
        data = json.loads(resultPayload)
        return data

    def _invokeGetREST(self,rest_conn,  url):
        rest_conn.request("GET", '/services/data/v%s/%s' % (_API_VERSION, url), headers=self.rest_headers)
        response = rest_conn.getresponse()
        resultPayload = response.read()
        if response.status != 200:
            print response.status, response.reason
            print resultPayload
            return None
        data = json.loads(resultPayload)
        return data

    def retrieve_meta(self, types, outputname='/tmp/retrieve.zip'):
        if not self.login_result:
            raise Exception('Initialization error: not logged in')
        if not self.meta:
            raise Exception('metadata API not initialized')
        request = self.meta.factory.create('RetrieveRequest')
        request.apiVersion = _API_VERSION
        pkg = self.meta.factory.create('Package')
        pkg.fullName = ['*']
        pkg.version = _API_VERSION
        pkg.apiAccessLevel = 'Unrestricted'
        pkgtypes = []
        for type in types:
            if type == 'CustomObject':
                pkgtypes.append(self._buildCustomObjectsPackage())
            else:
                pkgtype = self.meta.factory.create('PackageTypeMembers')
                pkgtype.members = ['*']
                pkgtype.name = type
                pkgtypes.append(pkgtype)
        pkg.types = pkgtypes
        request.unpackaged = [pkg]
        request.singlePackage = False

        countdown = _METADATA_TIMEOUT
        asyncResult = self.meta.service.retrieve(request)
        while not asyncResult.done:
            print 'polling..', str(countdown)
            time.sleep(_METADATA_POLL_SLEEP)
            countdown -= _METADATA_POLL_SLEEP
            if countdown <= 0: break
            asyncResult = self.meta.service.checkStatus([asyncResult.id])[0]

        if asyncResult.state != 'Completed':
            self.logger.error('Retrieving package: ' + asyncResult.message)
            raise Exception(asyncResult.message)

        result = self.meta.service.checkRetrieveStatus([asyncResult.id])

    #    if result.messages != None and len(result.messages) > 0:
    #        print 'Error: ' + '\n'.join([r.problem for r in result.messages])
    #        raise Exception('Retrieval error: ' + result.messages[0].problem)

        zip = binascii.a2b_base64(result.zipFile)
        out = file(outputname, 'w')
        out.write(zip)
        out.close()

    def deploy(self, zipfilename):
        zipfile = file(zipfilename, 'rb')
        zip = zipfile.read()
        zipfile.close()
        zip64 = binascii.b2a_base64(zip)
        deploy_options = self.meta.factory.create('DeployOptions')
        deploy_options.allowMissingFiles = False
        deploy_options.autoUpdatePackage = True
        deploy_options.checkOnly = False
        deploy_options.ignoreWarnings = False
        deploy_options.performRetrieve = False
        deploy_options.rollbackOnError = True
        deploy_options.runAllTests = False
        deploy_options.singlePackage = True

        result = self.meta.service.deploy(zip64, deploy_options)
        countdown = _DEPLOY_TIMEOUT
        while not result.done:
            print 'polling..', str(countdown)
            time.sleep(_DEPLOY_POLL_SLEEP)
            countdown -= _DEPLOY_POLL_SLEEP
            if countdown <= 0: raise Exception('Deployment timed out')
            result = self.meta.service.checkStatus([result.id])
            print "Status is: " + result.state
        if result.state != 'Completed':
            raise Exception(result.message)
        deployResult = self.meta.service.checkDeployStatus(result.id)
        if not deployResult.success:
            raise Exception('Deployment failed')


if __name__ == "__main__":
    print "Hello World"
