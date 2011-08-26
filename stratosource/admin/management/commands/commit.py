from django.core.management.base import BaseCommand, CommandError
from django.core.exceptions import ObjectDoesNotExist
from stratosource.admin.models import Branch, Commit, Delta, TranslationDelta
import subprocess
import popen2
from datetime import datetime
import os


__author__="masmith"
__date__ ="$Sep 22, 2010 2:11:52 PM$"

class Command(BaseCommand):

    def parse_commits(self, branch, start_date):
        cwd = os.getcwd()
        try:
            os.chdir(branch.repo.location)
            subprocess.check_call(["git","checkout",branch.name])
            subprocess.check_call(["git","reset","--hard","{0}".format(branch.name)])
            r,w = popen2.popen2("git log")
            commits = []
            hash = ""
            author = ""
            commitdate = ""
            comment = ""
            for line in r:
                line = line.rstrip()
                if line.startswith("commit "):
                    if len(hash) > 0:
                        if commitdate >= start_date:
                            map = {'hash':hash,'author':author,'date':commitdate,'comment':comment}
                            commits.append(map)
                        hash = ""
                        author = ""
                        commitdate = ""
                        comment = ""
                    hash = line[7:]
                elif line.startswith("Author: "):
                    author = line[8:]
                elif line.startswith("Date:  "):
                    commitdate = datetime.strptime(line[8:-6], '%a %b %d %H:%M:%S %Y')
#                    commitdate = line[8:]
                elif len(line) > 4:
                    comment += line.strip()
            if len(hash) > 0:
                map = {'hash':hash,'author':author,'date':commitdate,'comment':comment}
                commits.append(map)
            r.close()
            w.close()
            print 'commits = ' + str(len(commits))
            return commits
        finally:
            os.chdir(cwd)


    def handle(self, *args, **options):

        if len(args) < 2: raise CommandError('usage: <repo name> <branch>  {start date mm-dd-yyyy}')

        br = Branch.objects.get(repo__name__exact=args[0], name__exact=args[1])
        if not br: raise CommandException("invalid repo/branch")

        if len(args) == 3:
            start_date = datetime.strptime(args[2], '%m-%d-%Y')
        else:
            start_date = datetime(2000, 01, 01, 00, 00)

        commits = self.parse_commits(br, start_date)
        commits.reverse()       # !! must be in reverse chronological order from oldest to newest
        prev_commit = None
        for acommit in commits:
            try:
                existing = Commit.objects.get(hash__exact=acommit['hash'])
                if existing:
                    prev_commit = acommit
                    continue
            except ObjectDoesNotExist:
                pass

            print 'adding commit', acommit['hash'], 'for branch', br.name
            if prev_commit: print 'prev hash = ' + prev_commit['hash']
            newcommit = Commit()
            newcommit.branch = br
            newcommit.hash = acommit['hash']
            if prev_commit: newcommit.prev_hash = prev_commit['hash']
            newcommit.comment = acommit['comment']
            newcommit.date_added = acommit['date'] # datetime.strptime(acommit['date'][:-6], '%a %b %d %H:%M:%S %Y')
            newcommit.save()
            prev_commit = acommit
