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
from datetime import datetime
from stratosource.admin.models import Release
from stratosource.admin.models import Story
from stratosource.admin.models import Branch
from stratosource.admin.models import DeployableObject
from stratosource.admin.models import DeployableTranslation
from django.core.exceptions import ObjectDoesNotExist
from django.http import HttpResponse
from django.shortcuts import render_to_response
from django.template import RequestContext
from django.utils import simplejson
import logging


def createrelease(request):
    results = {'success':False}
    
    if request.method == u'GET':
        try:
            release = Release()
            release.name = request.GET['name']
            release.branch = Branch.objects.get(name=request.GET['branch'])
            release.est_release_date = request.GET['estRelDate']
            release.save()
            results = {'success':True}
        except Exception as ex:
            results = {'success':False, 'error':ex}

    json = simplejson.dumps(results)
    return HttpResponse(json, mimetype='application/json')

def updatereleasedate(request):
    results = {'success':False}

    if request.method == u'GET':
        try:
            release = Release.objects.get(id=request.GET['id'])
            date = request.GET['date']

            release.est_release_date = date
            release.save()
            results = {'success':True}
        except Exception as ex:
            results = {'success':False, 'error':ex}

    json = simplejson.dumps(results)
    return HttpResponse(json, mimetype='application/json')

def deleterelease(request):
    results = {'success':False}

    if request.method == u'GET':
        try:
            release = Release.objects.get(id=request.GET['id'])
            release.delete()
            results = {'success':True}
        except Exception as ex:
            results = {'success':False, 'error':ex}

    json = simplejson.dumps(results)
    return HttpResponse(json, mimetype='application/json')

def markreleased(request):
    results = {'success':False}

    if request.method == u'GET':
        try:
            release = Release.objects.get(id=request.GET['id'])
            release.released = True
            release.release_date = datetime.now()
            release.save()
            for story in release.stories.all():
                story.done_on_branches.add(release.branch)
                objects = DeployableObject.objects.filter(pending_stories=story, branch=release.branch)
                for object in objects:
                    object.pending_stories.remove(story)
                    object.released_stories.add(story)

                    non_releasing_stories = set()
                    for story in object.pending_stories.all():
                        if story not in release.stories.all():
                            non_releasing_stories.add(story)
                    
                    if (len(non_releasing_stories) == 0):
                        object.release_status = 'r';
                    object.save()
                translations = DeployableTranslation.objects.filter(pending_stories=story, branch=release.branch)
                for trans in translations:
                    trans.pending_stories.remove(story)
                    trans.released_stories.add(story)

                    non_releasing_stories = set()
                    for story in trans.pending_stories.all():
                        if story not in release.stories.all():
                            non_releasing_stories.add(story)
                    
                    if (len(non_releasing_stories) == 0):
                        trans.release_status = 'r';
                    trans.save()
            results = {'success':True}
        except Exception as ex:
            results = {'success':False, 'error':ex.message}

    json = simplejson.dumps(results)
    return HttpResponse(json, mimetype='application/json')

def releases(request):
    if request.method == u'GET':
        branch_name = request.GET['branch']
        releases = Release.objects.filter(hidden=False, branch__name__exact=branch_name).order_by('released', 'est_release_date', 'release_date', 'name')
        data = {'releases': releases , 'branch': branch_name}

        return render_to_response('ajax_releases.html', data, context_instance=RequestContext(request) )

def ignoreitem(request, object_id):
    results = {'success':False}
    ok = request.GET['ok']
    try:
        object = DeployableObject.objects.get(id=object_id)
        if ok == 'true':
            if len(object.pending_stories.all()) > 0:
                object.release_status = 'p'
            else:
                object.release_status = 'c'
            object.save()
            results = {'success':True}
        else:
            if len(object.pending_stories.all()) == 0:
                object.release_status = 'r'
                object.save()
                results = {'success':True}
            else:
                results = {'success': False, 'error': 'Object is assigned to a story'}
    except Exception as ex:
        results = {'success':False, 'error':ex}

    json = simplejson.dumps(results)
    return HttpResponse(json, mimetype='application/json')

def ignoretranslation(request, trans_id):
    results = {'success':False}
    ok = request.GET['ok']
    try:
        trans = DeployableTranslation.objects.get(id=trans_id)
        if ok == 'true':
            if len(trans.pending_stories.all()) > 0:
                trans.release_status = 'p'
            else:
                trans.release_status = 'c'
            trans.save()
            results = {'success':True}
        else:
            if len(trans.pending_stories.all()) == 0:
                trans.release_status = 'r'
                trans.save()
                results = {'success':True}
            else:
                results = {'success': False, 'error': 'At least one object is assigned to a story'}
    except Exception as ex:
        results = {'success':False, 'error':ex}

    json = simplejson.dumps(results)
    return HttpResponse(json, mimetype='application/json')

def ignoreselected(request):
    results = {'success':False}

    try:
        objectIds = request.GET.getlist('ii');

        objects = DeployableObject.objects.filter(id__in=objectIds)
        for object in objects:
            if len(object.pending_stories.all()) == 0:
                object.release_status = 'r'
                object.save()

        transIds = request.GET.getlist('ti');

        translations = DeployableTranslation.objects.filter(id__in=transIds)
        for translation in translations:
            if len(translation.pending_stories.all()) == 0:
                translation.release_status = 'r'
                translation.save()

        results = {'success':True}

    except Exception as ex:
        results = {'success':False, 'error':ex}

    json = simplejson.dumps(results)
    return HttpResponse(json, mimetype='application/json')

def addstoriestorelease(request):
    results = {'success':False}
    try:
        ids = request.GET['storyId'].split(',')
        release = Release.objects.get(id=request.GET['releaseid'])
        stories = Story.objects.filter(id__in=ids)
        for s in stories.all():
            if s not in release.stories.all():
                release.stories.add(s)
        release.save()
        
        results = {'success':True}
    except Exception as ex:
        results = {'success':False, 'error':ex.message}

    json = simplejson.dumps(results)
    return HttpResponse(json, mimetype='application/json')

def getstories(request):
    results = {'success':False}
    try:
        storyList = ['None|']
        stories = []
        sprint = 'All'
        if request.GET.__contains__('sprintName'):
            sprint = request.GET['sprintName'];
        if sprint != 'None':
            if len(sprint) > 0 and sprint != 'All':
                stories = Story.objects.filter(sprint=sprint).order_by('rally_id', 'name')
            else:
                stories = Story.objects.all().order_by('rally_id', 'name')
    
            for story in stories:
                if len(story.rally_id) > 0:
                    name = story.rally_id + ': '
    
                storyList.append(name + story.name + '|' + str(story.id))
        results = {'success':True, 'stories': storyList, 'numStories': len(stories)}
    except Exception as ex:
        results = {'success':False, 'error':ex.message}

    json = simplejson.dumps(results)
    return HttpResponse(json, mimetype='application/json')

def getsprints(request):
    results = {'success':False}
    try:
        sprintList = ['None','All']
        stories = Story.objects.filter(sprint__isnull=False).order_by('sprint')

        for story in stories:
            if len(story.sprint) > 0 and not sprintList.__contains__(story.sprint):
                sprintList.append(story.sprint)
        
        results = {'success':True, 'sprints': sprintList, 'numSprints': len(sprintList)}
    except Exception as ex:
        results = {'success':False, 'error':ex.message}

    json = simplejson.dumps(results)
    return HttpResponse(json, mimetype='application/json')


def addtostory(request):

    log = logging.getLogger('user')

    results = {'success':False}

    if request.method == u'GET':
        story = None;
        try:
            storyId = request.GET['storyId']
            storyName = request.GET['storyName']
            storyRallyId = request.GET['storyRallyId']
            storyURL = request.GET['storyURL']

            if len(storyId) > 0 or len(storyRallyId) > 0:

                if len(storyId) > 0:
                    try:
                        story = Story.objects.get(id=storyId)
                    except ObjectDoesNotExist:
                        pass

                if not story and len(storyRallyId) > 0:
                    try:
                        story = Story.objects.get(rally_id=storyRallyId)
                    except ObjectDoesNotExist:
                        pass

                if not story:
                    story = Story()
                    if len(storyRallyId) > 0:
                        story.rally_id = storyRallyId
                        story.url = "https://rally1.rallydev.com/slm/detail/" + story.rally_id
                    if len(storyURL) > 0:
                        story.url = storyURL

                if len(storyName) > 0:
                    story.name = storyName
                    
                story.save()
                
            objectIds = request.GET.getlist('itemid');

            objects = DeployableObject.objects.filter(id__in=objectIds)
            for object in objects:
                if story:
                    object.pending_stories.add(story)
                    object.release_status = 'p'
                object.save()

            transIds = request.GET.getlist('transid');

            translations = DeployableTranslation.objects.filter(id__in=transIds)
            for translation in translations:
                if story:
                    translation.pending_stories.add(story)
                    translation.release_status = 'p'
                translation.save()

            results = {'success':True}
        except Exception as ex:
            results = {'success':False, 'error':'ERROR: ' + ex.message}

    json = simplejson.dumps(results)
    return HttpResponse(json, mimetype='application/json')