
from suds.client import Client
import suds
import binascii
import time
import logging

__author__="mark"
__date__ ="$Aug 15, 2010 9:48:38 PM$"

_API_VERSION = 20.0
_DEFAULT_LOGNAME = '/tmp/agent.log'
_METADATA_TIMEOUT=60 * 10
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
        self.partner.service.logout()
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
