from django.core.management.base import BaseCommand, CommandError
from django.db.models import Q
from stratosource.admin.models import AdminMessage
import irclib
import threading
import time

instance = None


def watch_messages(channel):
    while True:
        time.sleep(30)
        print 'polling'
        msglist = AdminMessage.objects.filter(
            Q(to__contains='ircbot') | Q(to__contains='any')).exclude(handled_by__contains='ircbot').order_by('-event_time')
        for msg in msglist:
            print 'saying ' + msg.subject.encode('utf-8')
            instance.privmsg(channel, msg.subject.encode('utf-8'))
            msg.handled_by += 'ircbot'
            msg.save()


class Command(BaseCommand):

    def handle(self, *args, **options):

        if len(args) != 2: raise CommandError('usage: ircbot server channel')

        server = args[0]
        channel = args[1]
        if channel[0] != '#':  channel = '#' + channel

        msg_thread = threading.Thread(target=watch_messages, args=(args[1], ))
        msg_thread.daemon = True
        msg_thread.start()

        irc = irclib.IRC()
        server = irc.server()
        server.connect(server, 6667, 'CollabSrcBot', ircname = 'CollabSrcBot')
        server.join(channel)
        global instance
        instance = server
        # make sure we don't flood the channel with old messages
        msglist = AdminMessage.objects.filter(
            Q(to__contains='ircbot') | Q(to__contains='any')).exclude(handled_by__contains='ircbot').order_by('-event_time')
        for msg in msglist: msg.handled_by += 'ircbot'
        msglist.update()
        irc.process_forever()

