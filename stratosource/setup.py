from stratosource.admin.models import ConfigSetting
from django.core.exceptions import ObjectDoesNotExist

STANDARDCHKSETTINGS='rally.enabled'
STANDARDTXTSETTINGS='rally.login'
STANDARDPASSWORDS='rally.password'

for name in STANDARDTXTSETTINGS.split(','):
  s = ConfigSetting(key=name, value='', allow_delete=False, masked=False)
  s.save()

for name in STANDARDCHKSETTINGS.split(','):
  s = ConfigSetting(key=name, value='', type='check', allow_delete=False, masked=False)
  s.save()

for name in STANDARDPASSWORDS.split(','):
  s = ConfigSetting(key=name, value='', allow_delete=False, masked=True)
  s.save()

#try:
#    unReleased = Release.objects.get(name='Unreleased')
#    unReleased.name = 'Unreleased'
#    unReleased.hidden = True
#    unReleased.isdefault = True
#    unReleased.save()
#except ObjectDoesNotExist:
#    unReleased = Release()
#    unReleased.name = 'Unreleased'
#    unReleased.hidden = True
#    unReleased.isdefault = True
#    unReleased.save()

print 'done'
