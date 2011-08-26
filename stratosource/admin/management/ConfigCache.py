from stratosource.admin.models import ConfigSetting
from django.contrib.sessions.backends.db import SessionStore
from django.core.exceptions import ObjectDoesNotExist
import logging

logger = logging.getLogger('console')

__author__="tkruger"
__date__ ="$Aug 12, 2011 10:33:31 AM$"

session = SessionStore()

def refresh():
    settings = {}
    setList = ConfigSetting.objects.all()
    for setting in setList:
        logger.debug('Adding ' + setting.key)
        settings[setting.key] = setting.value
    session['settings'] = settings;

def get_config_value(key):
    if not session.has_key('settings'):
        logger.debug('Refreshing cachce')
        refresh()
    settings = session['settings']
    if settings.has_key(key):
        logger.debug('Returning ' + key)
        return settings[key]
    else:
        return ''

def store_config_value(key, value):
    try:
        setting = ConfigSetting.objects.get(key=key)
    except ObjectDoesNotExist:
        setting = ConfigSetting()
        setting.key = key

    setting.value = value
    setting.save()
    refresh()
