import socket
import urllib
import httplib

nickname = 'NICKNAMEHERE'
network = 'NETWORKHERE'
port = 6667
channel = '#CHANNELHERE'

irc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
irc.connect((network, port))

irc.recv(4096)
irc.send('NICK ' + nickname + '\r\n')
irc.send('USER ' + nickname + ' ' + nickname + ' ' + network + ' ' + ':' + nickname + '\r\n') #Change it up as needed -- just using this to get it running locally
irc.send('JOIN ' + channel + '\r\n')

while True:
    data = irc.recv(4096)
    print data

    if data.find('PING') != -1:
        irc.send('PONG ' + data.split()[1] + '\r\n')
    elif data.find('PRIVMSG') != -1:

        if data.find('!help') != -1:
            irc.send('PRIVMSG ' + channel + ' : Here are the available commands:\r\n')
            irc.send('PRIVMSG ' + channel + ' : 1. checkout -- assigns story work item in StratoSource -- !checkout <samplefilename.cls> <US#####>\r\n')

        if data.find('!checkout') != -1:
            a = data.split(':')
            b = a[2].split(' ')
            irc.send('PRIVMSG ' + channel + ' : ' + b[1] + '\r\n')
            irc.send('PRIVMSG ' + channel + ' : ' + b[2] + '\r\n')
            params = urllib.urlencode({
            'file_name'     : b[1].strip(),
            'story_num'     : b[2].strip()
            })
            irc.send('PRIVMSG ' + channel + ' : ' + params + '\r\n')
            headers = {"Content-type": "application/x-www-form-urlencoded", "Accept": "text/plain"}
            conntest = httplib.HTTPConnection("127.0.0.1", 8001)
            conntest.request("POST", "/services/stratohelper", params, headers)
            response = conntest.getresponse()

            responselines = str(response.read()).rsplit('****')

            for line in responselines:
                if str(line).startswith('['):
                    irc.send('PRIVMSG ' + channel + ' : ' + str(line) + '\r\n')
                else:
                    irc.send('PRIVMSG ' + channel + ' : ' + str(line) + '\r\n')