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
        agent.retrieve_meta(types, filename)
        agent.close()
        self.logger.debug('finished download')

        if not downloadOnly:
            from admin.management.checkin import perform_checkin
            perform_checkin(br.repo.location, filename, br.name)
            os.remove(filename)

