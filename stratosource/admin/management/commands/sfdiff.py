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
import os
import sys
import subprocess
from datetime import datetime
from django.db import transaction
from lxml import etree
from stratosource.admin.models import Branch, Commit, Repo, Delta, DeployableTranslation, TranslationDelta, DeployableObject, AdminMessage, UserChange


__author__="masmith"
__date__ ="$Jul 26, 2010 2:23:44 PM$"

SF_NAMESPACE='{http://soap.sforce.com/2006/04/metadata}'
CODE_BASE = 'unpackaged'

documentCache = {}
mapCache = {}

class NewObjectException(Exception):
    pass

class DeletedObjectException(Exception):
    pass


##
# [ git utilities ]
##

def resetLocalRepo(branch_name):
    subprocess.check_call(["git","checkout",branch_name])
#    subprocess.check_call(["git","reset","--hard","{0}".format(branch_name)])

def branchExists(branchname):
    proc = subprocess.Popen(['git','branch','-a'], shell=False, stdout=subprocess.PIPE)
    input,error = proc.communicate()
    for br in input.split('\n'):
        br = br.rstrip()
        if len(br) > 0 and br[2:] == branchname: return True
    return False

def getCurrentTag():
    proc = subprocess.Popen(['git','describe'], shell=False, stdout=subprocess.PIPE)
    input,error = proc.communicate()
    tag = input.rstrip()
    return tag

def getCurrentBranch():
    proc = subprocess.Popen(['git','branch'], shell=False, stdout=subprocess.PIPE)
    input,error = proc.communicate()
    for br in input.split('\n'):
        br = br.rstrip()
        if len(br) > 0 and br[0:2] == "* ":
            return br[2:]
    return 'unknown'

def verifyGitRepo():
    proc = subprocess.Popen(['git','status'], shell=False, stderr=subprocess.PIPE)
    input,error = proc.communicate()
    if error.find('Not a git repository') > 0:
        print 'Error: Not a git repository'
        sys.exit(1)


def getDiffNames(left, right):
    print 'git diff --name-only %s %s' % (left, right)
    proc = subprocess.Popen(['git','diff','--name-only',left,right], shell=False, stdout=subprocess.PIPE)
    input,error = proc.communicate()
    changedList = []
    all = 0
    map = {}
    for entry in input.split('\n'):
        all = all + 1
        entry = entry.rstrip()
        if entry == '.gitignore': continue
        if len(entry) > 1 and not entry.endswith('.xml'):
            parts = entry.split('/')
            type = parts[1]
            print 'type=' + type
            a,b = os.path.split(entry)
            #base,type = os.path.split(a)
            if not map.has_key(type): map[type] = []
            map[type].append(b)
            changedList.append(entry)

    changedList.sort()
    return map


##
# [ XML parsing and searching ]
##

def getElementMap(key):
    global mapCache

    if mapCache.has_key(key):
        return mapCache[key]
    m = {}
    mapCache[key] = m
    return m


def getObjectChanges(lkey, lcache, rkey, rcache, objectName, elementName, resolver):

    global documentCache

    ldoc = None
    rdoc = None

    if documentCache.has_key(lkey + objectName): ldoc = documentCache[lkey + objectName]
    if documentCache.has_key(rkey + objectName): rdoc = documentCache[rkey + objectName]

    rmap = getElementMap(rkey + objectName + elementName)
    lmap = getElementMap(lkey + objectName + elementName)

    if ldoc is None:
        lobj = lcache.get(objectName)
        if lobj:
            ldoc = etree.XML(lobj)
            if ldoc is None: return None, None
            documentCache[lkey + objectName] = ldoc
    if rdoc is None:
        robj = rcache.get(objectName)
        if robj:
            rdoc = etree.XML(robj)
            if rdoc is None: return None, None
            documentCache[rkey + objectName] = rdoc

    if ldoc is None and not rdoc is None:
        raise NewObjectException()
    if not ldoc is None and rdoc is None:
        raise DeletedObjectException()

    return resolver(ldoc, rdoc, rmap, lmap, elementName)

def compareObjectMaps(lmap, rmap):
    missing = {}
    updates = {}

    for lname, lnodestring in lmap.items():
        # find the field in the other file
        if rmap.has_key(lname):
            rnodestring = rmap[lname]
            # compare for changes
            if lnodestring != rnodestring:
                updates[lname] = rnodestring
        else:
            # field missing on right, must be deleted
            missing[lname] = lnodestring
    return updates, missing

def populateElementMap(doc, nodeName, elementName, amap):
    if doc != None and len(amap) == 0:
        children = doc.findall(nodeName)
        for child in children:
            node = child.find(elementName)
            amap[node.text] = etree.tostring(child)

def objectChangeResolver(ldoc, rdoc, rmap, lmap, elementName):
    nodeName = SF_NAMESPACE + elementName
    nameKey = SF_NAMESPACE + 'fullName'
    #
    # build a map of custom label names and xml fragment for faster lookups
    #
    populateElementMap(rdoc, nodeName, nameKey, rmap)
    populateElementMap(ldoc, nodeName, nameKey, lmap)
    return compareObjectMaps(lmap, rmap)

def objectTranslationChangeResolver(ldoc, rdoc, rmap, lmap, elementName):
    nodeName = SF_NAMESPACE + elementName
    nameKey = SF_NAMESPACE + 'name'
    #
    # build a map of custom label names and xml fragment for faster lookups
    #
    populateElementMap(rdoc, nodeName, nameKey, rmap)
    populateElementMap(ldoc, nodeName, nameKey, lmap)
    return compareObjectMaps(lmap, rmap)

def translationChangeResolver(ldoc, rdoc, rmap, lmap, elementName):
    nodeName = SF_NAMESPACE + elementName
    nameKey = SF_NAMESPACE + 'name'
    #
    # build a map of custom label names and xml fragment for faster lookups
    #
    populateElementMap(rdoc, nodeName, nameKey, rmap)
    populateElementMap(ldoc, nodeName, nameKey, lmap)
    return compareObjectMaps(lmap, rmap)


def getAllFullNames(doc, elementName, tagname='fullName'):
    fqfullname = SF_NAMESPACE + tagname
    nodes = doc.findall(SF_NAMESPACE + tagname)
    all = [node.find(fqfullname).text for node in nodes]
    return all


def getAllObjectChanges(objectName, lFileCache, rFileCache, elementname, resolver):
    updates, deletes = getObjectChanges('l', lFileCache, 'r', rFileCache, objectName, elementname, resolver)
    rupdates, inserts = getObjectChanges('r', rFileCache, 'l', lFileCache, objectName, elementname, resolver)
    return inserts, updates, deletes


##
# [ database and caching ]
##

def createFileCache(hash, map, branch_name):
    tmpbranch = branch_name + '_sfdiff'
    subprocess.check_call(["git","checkout",branch_name])
    if branchExists(tmpbranch):
        subprocess.check_call(["git","branch","-D",tmpbranch])
    subprocess.check_call(["git","checkout","-b",tmpbranch, branch_name])
    os.system('git reset --hard {0}'.format(hash))
    cache = {}
    for type,list in map.items():
        if type in ('objects','labels','translations','objectTranslations', 'workflows'):
            for objectName in list:
                try:
                    path = os.path.join(CODE_BASE,type,objectName)
                    f  = open(path)
                    cache[objectName] = f.read()
                    f.close()
                except IOError:
                    #print '** not able to load ' + path
                    pass    # caused by a new file added, not present on current branch
        else:
            for objectName in list:
                if os.path.isfile(os.path.join(CODE_BASE,type,objectName)):
                    cache[objectName] = None
    return cache


def getDeployable(branch, objectName, objectType, el_type, el_name, el_subtype = None):
    try:
        if el_type and el_name:
            deployable = DeployableObject.objects.get(branch=branch, type__exact=objectType,filename__exact=objectName,
                                el_type__exact=el_type,el_name__exact=el_name,el_subtype__exact=el_subtype,
                                status__exact='a')
        else:
            deployable = DeployableObject.objects.get(branch=branch,type__exact=objectType,filename__exact=objectName,status__exact='a')
    except ObjectDoesNotExist:
        deployable = DeployableObject()
        deployable.type = objectType
        deployable.filename = objectName
        deployable.branch = branch
        deployable.el_type = el_type
        deployable.el_name = el_name
        deployable.el_subtype = el_subtype
        deployable.save()
    return deployable


def insertDeltas(commit, objectName, type, items, delta_type, el_type, el_subtype = None):
    for item in items:
        deployable = getDeployable(commit.branch, objectName, type, el_type, item, el_subtype)
        delta = Delta()
#        delta.last_change = getLastChange(objectName)
        delta.object = deployable
        delta.commit = commit
        delta.delta_type = delta_type
        delta.save()
#        xtra = ''
#        if not el_type is None: xtra += ' el_type=' + el_type
#        print 'DELTA: object=' + deployable.filename + 'item=' + item + ', delta_type=' + delta_type + xtra

def getLastChange(objectName):
    recents = list(UserChange.objects.filter(apex_name__exact=objectName).order_by('last_update').reverse()[:1])
    if len(recents) == 0:
        return None
        return recents[0]

def getDeployableTranslation(branch, label, locale):
    try:
        deployableT = DeployableTranslation.objects.get(branch=branch,label=label, locale=locale,status__exact='a')
    except ObjectDoesNotExist:
        deployableT = DeployableTranslation()
        deployableT.label = label
        deployableT.locale = locale
        deployableT.branch = branch
        deployableT.save()
    return deployableT


def insertTranslationDeltas(commit, items, delta_type, locale):
    for item in items:
        deployableT = getDeployableTranslation(commit.branch, item, locale)
        delta = TranslationDelta()
        delta.translation = deployableT
        delta.commit = commit
        delta.delta_type = delta_type
        delta.save()

##
# [ objects ]
##
def analyzeObjectChanges(list, lFileCache, rFileCache, elementname, commit):
    global documentCache

    changesFound = False
    for objectName in list:
        try:
#            print'  object name is', objectName, 'element name is', elementname
            inserts, updates, deletes = getAllObjectChanges(objectName, lFileCache, rFileCache, elementname, objectChangeResolver)
            if (inserts and len(inserts)) or (updates and len(updates)) or (deletes and len(deletes)):
                if inserts: insertDeltas(commit, objectName, 'objects', inserts.keys(), 'a', elementname)
                if updates: insertDeltas(commit, objectName, 'objects', updates.keys(), 'u', elementname)
                if deletes: insertDeltas(commit, objectName, 'objects', deletes.keys(), 'd', elementname)
                changesFound = True

        except NewObjectException:
            doc = documentCache['r' + objectName]
            insertDeltas(commit, objectName, 'objects', getAllFullNames(doc, elementname), 'a', elementname)

        except DeletedObjectException:
            doc = documentCache['l' + objectName]
            insertDeltas(commit, objectName, 'objects', getAllFullNames(doc, elementname), 'd', elementname)

    if not changesFound:
        pass

##
# [ objectTranslation ]
##
def analyzeObjectTranslationChanges(list, lFileCache, rFileCache, elementname, commit):
    global documentCache

    changesFound = False
    for objectName in list:
        try:
            #print 'OBJECT NAME ' + objectName
            inserts, updates, deletes = getAllObjectChanges(objectName, lFileCache, rFileCache, elementname, objectTranslationChangeResolver)
            if (inserts and len(inserts)) or (updates and len(updates)) or (deletes and len(deletes)):
                if inserts: insertDeltas(commit, objectName, 'objectTranslations', inserts.keys(), 'a', elementname)
                if updates: insertDeltas(commit, objectName, 'objectTranslations', updates.keys(), 'u', elementname)
                if deletes: insertDeltas(commit, objectName, 'objectTranslations', deletes.keys(), 'd', elementname)
                changesFound = True

        except NewObjectException:
            doc = documentCache['r' + objectName]
            insertDeltas(commit, objectName, 'objectTranslations', getAllFullNames(doc, elementname), 'a', elementname)

        except DeletedObjectException:
            doc = documentCache['l' + objectName]
            insertDeltas(commit, objectName, 'objectTranslations', getAllFullNames(doc, elementname), 'd', elementname)

    if not changesFound:
        pass

##
# [ labels ]
##
def analyzeLabelChanges(list, lFileCache, rFileCache, elementname, commit):
    global documentCache

    for objectName in list:
        try:
            inserts, updates, deletes = getAllObjectChanges(objectName, lFileCache, rFileCache, elementname, objectChangeResolver)
            if (inserts and len(inserts)) or (updates and len(updates)) or (deletes and len(deletes)):
                if inserts: insertDeltas(commit, objectName, 'labels', inserts.keys(), 'a', elementname)
                if updates: insertDeltas(commit, objectName, 'labels', updates.keys(), 'u', elementname)
                if deletes: insertDeltas(commit, objectName, 'labels', deletes.keys(), 'd', elementname)

        except NewObjectException:
            doc = documentCache['r' + objectName]
            insertDeltas(commit, objectName, 'labels', getAllFullNames(doc, elementname), 'a', elementname)

        except DeletedObjectException:
            doc = documentCache['l' + objectName]
            insertDeltas(commit, objectName, 'labels', getAllFullNames(doc, elementname), 'd', elementname)

##
# [ translations ]
##
def analyzeTranslationChanges(list, lFileCache, rFileCache, commit):
    global documentCache

    for objectName in list:
        locale = objectName[:-12]   # the locale is part of the object name
        try:
            inserts, updates, deletes = getAllObjectChanges(objectName, lFileCache, rFileCache, 'customLabels', translationChangeResolver)
            if (inserts and len(inserts)) or (updates and len(updates)) or (deletes and len(deletes)):
                if inserts: insertTranslationDeltas(commit, inserts.keys(), 'a', locale)
                if updates: insertTranslationDeltas(commit, updates.keys(), 'u', locale)
                if deletes: insertTranslationDeltas(commit, deletes.keys(), 'd', locale)

        except NewObjectException:
            doc = documentCache['r' + objectName]
            insertDeltas(commit, objectName, 'translations', getAllFullNames(doc, 'customLabels', tagname='name'), 'a', 'customLabels')

        except DeletedObjectException:
            doc = documentCache['l' + objectName]
            insertDeltas(commit, objectName, 'translations', getAllFullNames(doc, 'customLabels', tagname='name'), 'd', 'customLabels')

##
# [ record types/picklists ]
##

def recTypePicklistResolver(ldoc, rdoc, rmap, map, elementName):
    missing = {}
    updates = {}
    inserts = {}

    if ldoc is None:
        lnodes = []
    else:
        lnodes = ldoc.findall(SF_NAMESPACE + elementName)
    if rdoc is None:
        rnodes = []
    else:
        rnodes = rdoc.findall(SF_NAMESPACE + elementName)

    #
    # put the left and right lists in a hash for easier analysis
    #
    fqfullname =        SF_NAMESPACE + 'fullName'
    fqpicklistvalues =  SF_NAMESPACE + 'picklistValues'
    fqpicklist =        SF_NAMESPACE + 'picklist'

    llists = {}
    for lnode in lnodes:
        fullName = lnode.find(fqfullname).text
        lpicklists = lnode.findall(fqpicklistvalues)
        for lpicklist in lpicklists:
            lpicklist_name = lpicklist.find(fqpicklist).text
            llists[fullName+':'+lpicklist_name] = etree.tostring(lpicklist)

    rlists = {}
    for rnode in rnodes:
        fullName = rnode.find(fqfullname).text
        rpicklists = rnode.findall(fqpicklistvalues)
        for rpicklist in rpicklists:
            rpicklist_name = rpicklist.find(fqpicklist).text
            rlists[fullName+':'+rpicklist_name] = etree.tostring(rpicklist)

    #
    # go down the left side lookup for updates and deletes
    #
    for lrectype_name in llists.keys():
        if rlists.has_key(lrectype_name):
            if rlists[lrectype_name] != llists[lrectype_name]:
                updates[lrectype_name] = rlists[lrectype_name]
        else:
            missing[lrectype_name] = llists[lrectype_name]

    #
    # go down the right side looking for additions
    #
    for rrectype_name in rlists.keys():
        if not llists.has_key(rrectype_name):
            inserts[rrectype_name] = rlists[rrectype_name]

    return inserts, updates, missing


def analyzeRecordTypeChanges(list, lFileCache, rFileCache, commit):
    global documentCache

    for objectName in list:
        try:
            inserts, updates, deletes = getObjectChanges('l', lFileCache, 'r', rFileCache, objectName, 'recordTypes', recTypePicklistResolver)
            if inserts: insertDeltas(commit, objectName, 'objects', inserts, 'a', 'recordTypes', 'picklists')
            if updates: insertDeltas(commit, objectName, 'objects', updates, 'u', 'recordTypes', 'picklists')
            if deletes: insertDeltas(commit, objectName, 'objects', deletes, 'd', 'recordTypes', 'picklists')

        except NewObjectException:
            doc = documentCache['r' + objectName]
            insertDeltas(commit, objectName, 'objects', getAllFullNames(doc, 'recordTypes', tagname='name'), 'a', 'recordTypes')

        except DeletedObjectException:
            doc = documentCache['l' + objectName]
            insertDeltas(commit, objectName, 'objects', getAllFullNames(doc, 'recordTypes', tagname='name'), 'd', 'recordTypes')

##
# [ workflows ]
##
def analyzeWorkflowChanges(list, lFileCache, rFileCache, elementname, commit):
    global documentCache

    changesFound = False
    for objectName in list:
        try:
#            print'  object name is', objectName, 'element name is', elementname
            inserts, updates, deletes = getAllObjectChanges(objectName, lFileCache, rFileCache, elementname, objectChangeResolver)
            if (inserts and len(inserts)) or (updates and len(updates)) or (deletes and len(deletes)):
                if inserts: insertDeltas(commit, objectName, 'workflows', inserts.keys(), 'a', elementname)
                if updates: insertDeltas(commit, objectName, 'workflows', updates.keys(), 'u', elementname)
                if deletes: insertDeltas(commit, objectName, 'workflows', deletes.keys(), 'd', elementname)
                changesFound = True

        except NewObjectException:
            doc = documentCache['r' + objectName]
            insertDeltas(commit, objectName, 'workflows', getAllFullNames(doc, elementname), 'a', elementname)

        except DeletedObjectException:
            doc = documentCache['l' + objectName]
            insertDeltas(commit, objectName, 'workflows', getAllFullNames(doc, elementname), 'd', elementname)

    if not changesFound:
        pass


@transaction.commit_on_success
def analyzeCommit(branch, commit):
    global documentCache
    global mapCache

    documentCache = {}  # do not want to accumulate this stuff over multiple iterations
    mapCache = {}

    # clean up deltas in case we are rerunning
    Delta.objects.filter(commit=commit).delete()
    TranslationDelta.objects.filter(commit=commit).delete()

    lhash = commit.prev_hash
    rhash = commit.hash

    print 'analyzing ' + rhash

    ##
    # call "git diff" to get a list of changed files
    ##
    map = getDiffNames(lhash, rhash)

    ##
    # load all changed files from each hash into a map for performance
    ##
    lFileCache = createFileCache(lhash, map, branch.name)
    rFileCache = createFileCache(rhash, map, branch.name)

    for type,list in map.items():
        #print type
        if type == 'objects':
            analyzeObjectChanges(list, lFileCache, rFileCache, 'fields', commit)
            analyzeObjectChanges(list, lFileCache, rFileCache, 'validationRules', commit)
            analyzeObjectChanges(list, lFileCache, rFileCache, 'webLinks', commit)
            analyzeRecordTypeChanges(list, lFileCache, rFileCache, commit)
            analyzeObjectChanges(list, lFileCache, rFileCache, 'namedFilters', commit)
            analyzeObjectChanges(list, lFileCache, rFileCache, 'listViews', commit)
            # misc single-node elements
#                analyzeObjectChanges(list, lFileCache, rFileCache, 'label', commit)
#                analyzeObjectChanges(list, lFileCache, rFileCache, 'nameField', commit, nameKey='label')
#                analyzeObjectChanges(list, lFileCache, rFileCache, 'pluralLabel', commit)
#                analyzeObjectChanges(list, lFileCache, rFileCache, 'searchLayouts', commit)
#                analyzeObjectChanges(list, lFileCache, rFileCache, 'sharingModel', commit)

        elif type == 'translations':
            analyzeTranslationChanges(list, lFileCache, rFileCache, commit)

        elif type == 'workflows':
            analyzeWorkflowChanges(list, lFileCache, rFileCache, 'alerts', commit)
            analyzeWorkflowChanges(list, lFileCache, rFileCache, 'fieldUpdates', commit)
            analyzeWorkflowChanges(list, lFileCache, rFileCache, 'rules', commit)
            analyzeWorkflowChanges(list, lFileCache, rFileCache, 'tasks', commit)

        elif type == 'objectTranslations':
            analyzeObjectTranslationChanges(list, lFileCache, rFileCache, 'fields', commit)
            analyzeObjectTranslationChanges(list, lFileCache, rFileCache, 'validationRules', commit)
            analyzeObjectTranslationChanges(list, lFileCache, rFileCache, 'webLinks', commit)

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

    commit.status = 'c'
    commit.save()


def generateAnalysis(branch, start_date):
    global documentCache

    commits = Commit.objects.filter(branch=branch,status__exact='p',prev_hash__isnull=False,date_added__gte=start_date).order_by('-date_added')

    for commit in commits:
        if commit.prev_hash is None: continue
        analyzeCommit(branch, commit)

#    msg = AdminMessage()
#    msg.subject = branch.name + ' commits processed'
#    msg.body = '%d %s commits were processed on %s' % (len(commits), branch.name, str(datetime.now()))
#    msg.sender = 'sfdiff'
#    msg.save()

##
# [ Entry point ]
##

class Command(BaseCommand):

    def handle(self, *args, **options):
        global documentCache

        if len(args) < 2: raise CommandError('usage: sfdiff <repo alias> <branch> {start date mm-dd-yyyy}')
        repo = Repo.objects.get(name__exact=args[0])
        branch = Branch.objects.get(repo=repo, name__exact=args[1])

        if len(args) == 3:
            start_date = datetime.strptime(args[2], '%m-%d-%Y')
        else:
            start_date = datetime(2000, 01, 01, 00, 00)

        os.chdir(repo.location)

        ##
        # some basic housekeeping
        ##
        resetLocalRepo(branch.name)
        verifyGitRepo()

        generateAnalysis(branch, start_date)
        
        documentCache = {}  # just in case running stateful by django middleware, clear out between calls

        # try to leave repo in a good state
        resetLocalRepo(branch.name)

