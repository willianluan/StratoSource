
import logging
import logging.config
import os


##
# Location constants
##
_CSHOME='/usr/django/stratosource'
CSCONF_DIR=os.path.join(_CSHOME, 'conf')
CS_SF_API_VERSION = '20.0'



def loadFile(name):
   with file(name) as f:
       return f.read()


logging.config.fileConfig(os.path.join(CSCONF_DIR, 'logging.conf'))
#logging.basicConfig(filename='/tmp/cloudsrc.log', level=logging.DEBUG)

