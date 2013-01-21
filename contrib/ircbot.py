#    Copyright 2010, 2011, 2012, 2013 Red Hat Inc.
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
#
# This working example demonstrates how to connect to RabbitMQ and receive
# informational notices from Stratosource, then output to an IRC channel.  It may
# be modified to send out emails or perform other activities.
#
# In a later release there will be multiple queues and messages will be
# properly categorized.
# 
# You must have RabbitMQ (http://www.rabbitmq.com/install-rpm.html) installed
# and running on the Stratosource machine. No additional configuration is
# necessary since Stratosource will detect it and begin publishing messages.
#
#

import irclib
import sys
import threading
import time
import pika



def callback(ch, method, properties, body):
    print " [x] %r" % (body,)
    instance.privmsg(channel, body.encode('utf-8'))


def watch_messages(channel):
    connection = pika.BlockingConnection(pika.ConnectionParameters(host=mqservername))
    channel = connection.channel()
    channel.exchange_declare(exchange='notices', type='fanout')
    result = channel.queue_declare(exclusive=True)
    queue_name = result.method.queue
    channel.queue_bind(exchange='notices', queue=queue_name)
    channel.basic_consume(callback, queue=queue_name, no_ack=True)
    channel.start_consuming()



if __name__ == '__main__':
    global instance, mqservername

    instance = None
    if len(sys.argv) != 4:
        print 'usage: ircbot mq-server server channel'
        exit(0)

    mqservername = sys.argv[1]
    servername = sys.argv[2]
    channel = sys.argv[3]
    if channel[0] != '#':  channel = '#' + channel

    msg_thread = threading.Thread(target=watch_messages, args=(sys.argv[2], ))
    msg_thread.daemon = True
    msg_thread.start()

    irc = irclib.IRC()
    server = irc.server()
    server.connect(servername, 6667, u'StratoSrcBot', ircname = u'StratoSrcBot')
    server.join(channel)
    instance = server
    irc.process_forever()

