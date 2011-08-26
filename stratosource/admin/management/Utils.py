from admin.management import CSBase
import os
import logging
from admin.management.SalesforceAgent import SalesforceAgent


__author__="mark"
__date__ ="$Sep 14, 2010 9:09:55 PM$"

def getAgentForBranch(branch):
    logger = logging.getLogger(__name__)

    user = branch.api_user
    password = branch.api_pass
    authkey = branch.api_auth
    if authkey is None: authkey = ''
    path = branch.api_store
    types = branch.api_assets.split(',')
    svcurl = 'https://' + branch.api_env + '.salesforce.com/services/Soap/u/' + branch.api_ver

    logger.debug("user='%s' path='%s' types=[%s] url='%s'", user, path, ' '.join(types), svcurl)

    partner_wsdl = 'file://' + os.path.join(CSBase.CSCONF_DIR, 'partner.wsdl')
    meta_wsdl = 'file://' + os.path.join(CSBase.CSCONF_DIR, 'metadata.wsdl')
    agent = SalesforceAgent(partner_wsdl, meta_wsdl)

    agent.login(user, password+authkey,server_url=svcurl)
    return agent

