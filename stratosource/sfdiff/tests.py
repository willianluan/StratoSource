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
from stratosource.admin.management.commands.sfdiff import *
from stratosource.admin.models import Commit, Release, Delta, Branch, Repo, DeployableObject
from django.test import TestCase
from django.core import serializers
import filecmp



def difflist():
    f = file('sfdiff/testfiles/difflist.txt')
    input = f.readlines()
    f.close()
    changedList = []
    all = 0
    map = {}
    for entry in input:
        all = all + 1
        entry = entry.rstrip()
        if len(entry) > 1 and not entry.endswith('.xml'):
            a,b = os.path.split(entry)
            base,type = os.path.split(a)
            if not map.has_key(type): map[type] = []
            map[type].append(b)
            changedList.append(entry)

    changedList.sort()
    return map

def createFileCache(dir, map):
    cache = {}
    for type,list in map.items():
        if type in ('objects','labels','translations'):
            for objectName in list:
                try:
                    path = os.path.join(dir, 'unpackaged',type,objectName)
                    f  = open(path)
                    cache[objectName] = f.read()
                    f.close()
                except IOError:
                    #print '** not able to load ' + path
                    pass    # caused by a new file added, not present on current branch
        else:
            for objectName in list:
                if os.path.isfile(os.path.join(dir, 'unpackaged',type,objectName)):
                    cache[objectName] = None
    return cache



class DiffTest(TestCase):

    def test_large_diff(self):
        map = difflist()

        ##
        # load all changed files from each hash into a map for performance
        ##
        lFileCache = createFileCache('sfdiff/testfiles/ltest', map)
        rFileCache = createFileCache('sfdiff/testfiles/rtest', map)

        repo = Repo()
        repo.location = '/tmp'
        repo.save()

        branch = Branch()
        branch.name = 'test'
        branch.repo = repo
        branch.save()

        rel = Release()
        rel.isdefault = True
        rel.name = 'test'
        rel.branch = branch
        rel.save()

        commit = Commit()
        commit.branch = branch
        commit.hash = 'test'
        commit.status = 'p'
        commit.save()

        for type,list in map.items():
            if type == 'objects':
                analyzeObjectChanges(list, lFileCache, rFileCache, 'fields', commit)
                analyzeObjectChanges(list, lFileCache, rFileCache, 'validationRules', commit)
                analyzeObjectChanges(list, lFileCache, rFileCache, 'webLinks', commit)
                analyzeRecordTypeChanges(list, lFileCache, rFileCache, commit)
                analyzeObjectChanges(list, lFileCache, rFileCache, 'namedFilters', commit)

            elif type == 'translations':
                analyzeTranslationChanges(list, lFileCache, rFileCache, commit)

            elif type == 'labels':
                analyzeLabelChanges(list, lFileCache, rFileCache, 'labels', commit)

            else:
                for listitem in list:
                    delta_type = None
                    if lFileCache.has_key(listitem) and rFileCache.has_key(listitem) == False:
                        delta_type = 'd'
                    elif lFileCache.has_key(listitem) == False:
                        delta_type = 'a'
                    else:
                        delta_type = 'u'

                    delta = Delta()
                    delta.object = getDeployable(branch, listitem, type, None, None, None)
                    delta.commit = commit
                    delta.delta_type = delta_type
                    delta.save()

        output = file('/tmp/deltas.json', 'w')
        output.write(serializers.serialize('json', Delta.objects.all(), indent=2))
        output.close()
        output = file('/tmp/deployables.json', 'w')
        output.write(serializers.serialize('json', DeployableObject.objects.all(), indent=2))
        output.close()

        self.assertTrue(filecmp.cmp('/tmp/deltas.json', 'sfdiff/testfiles/results/deltas.json', False), 'delta mismatch')
        self.assertTrue(filecmp.cmp('/tmp/deployables.json', 'sfdiff/testfiles/results/deployables.json', False), 'deployable mismatch')



