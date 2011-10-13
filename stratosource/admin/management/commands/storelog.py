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
from django.core.exceptions import ObjectDoesNotExist
from stratosource.admin.models import Branch, BranchLog
import os
import fileinput


__author__="jkruger"
__date__ ="$Oct 13, 2011 9:19 AM$"

class Command(BaseCommand):


    def handle(self, *args, **options):

        if len(args) < 4: raise CommandError('usage: <repo name> <branch> <file> <run_status>')

        br = Branch.objects.get(repo__name__exact=args[0], name__exact=args[1])
        if not br: raise CommandException("invalid repo/branch")
        br.run_status = args[3]
        br.save()
        
        brlog = BranchLog()
        
        try:
            brlog = BranchLog.objects.get(branch=br)
        except ObjectDoesNotExist:
            brlog.branch = br

        lastlog = 'From ' + args[2] + '<br/>'
        
        for line in fileinput.input(args[2]):
            lastlog += line + '<br/>'
            
        if len(lastlog) > 20000:
            lastlog = lastlog[len(lastlog) - 20000]
        brlog.lastlog = lastlog
        brlog.save()
