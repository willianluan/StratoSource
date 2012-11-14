
from stratosource.admin.models import CalendarEvent
from django.core.exceptions import ObjectDoesNotExist


def addCalendarReleaseEvent(release_id, release_name, relDate):
    event = CalendarEvent()
    event.subject = release_name
    event.startTime = relDate
    event.endTime = relDate
    event.isAllDayEvent = 1
    event.release_id = release_id
    event.save()

def updateCalendarReleaseEvent(relid, relDate):
    try:
        event = CalendarEvent.objects.get(release_id=relid)
        event.startTime = relDate
        event.endTime = relDate
        event.save()
    except ObjectDoesNotExist:
        pass

def removeCalendarReleaseEvent(release_id):
    try:
        event = CalendarEvent.objects.get(release_id=release_id)
        event.delete()
    except ObjectDoesNotExist:
        pass


