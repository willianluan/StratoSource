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
from django.core.management.base import BaseCommand, CommandError
import logging
import time
import os
from admin.models import Branch
import admin.management.CSBase # used to initialize logging
from admin.management import Utils

__author__="mark"
__date__ ="$Sep 7, 2010 9:02:55 PM$"


class Command(BaseCommand):
    logger = logging.getLogger('download')
    args = ''
    help = 'download assets from Salesforce'

    def handle(self, *args, **options):

        if len(args) < 2: raise CommandError('usage: <repo name> <branch>')

        br = Branch.objects.get(repo__name__exact=args[0], name__exact=args[1])
        if not br: raise CommandException("invalid repo/branch")

        downloadOnly = False
        if len(args) > 2 and args[2] == '--download-only': downloadOnly = True

        agent = Utils.getAgentForBranch(br)

        path = br.api_store
        types = [aType.strip() for aType in br.api_assets.split(',')]

        stamp = str(int(time.time()))
        filename = os.path.join(path, 'retrieve_{0}.zip'.format(stamp))
        print 'retrieving %s:%s' % (br.repo.name, br.name)
        print 'types: ' + br.api_assets
#        agent.retrieve_meta(types, filename)
        classes, triggers, pages = agent.retrieve_userchanges()
        agent.close()
        self.logger.debug('finished download')

        if not downloadOnly:
            from admin.management.checkin import perform_checkin, save_userchanges
#            perform_checkin(br.repo.location, filename, br, userchanges=(classes,triggers,pages))
            save_userchanges(br, classes,triggers,pages)
#            os.remove(filename)

