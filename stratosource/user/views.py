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
from datetime import date
from datetime import datetime
from datetime import timedelta
from django.utils.encoding import smart_str
import re
from django.template import RequestContext
from django.shortcuts import render_to_response, redirect
from stratosource.admin.models import Story, Release, DeployableObject, DeployableTranslation, Delta, Branch, ConfigSetting
from stratosource.user.rallyintegration import get_stories, get_projects
from stratosource.admin.management import ConfigCache
import logging

logger = logging.getLogger('console')
namestl = {
            'homePageComponents'    :'Homepage Components',
            'homePageLayouts'       :'Homepage Layouts',
            'objectTranslations'    :'Object Translations',
            'reportTypes'           :'Report Types',
            'remoteSiteSettings'    :'Remote Site Settings',
            'staticresources'       :'Static Resources',
            'scontrols'             :'S-Controls',
            'weblinks'              :'Web Links'
        }


def configs(request):
    allsettings = ConfigSetting.objects.all();

    if request.method == u'POST':
        params = dict(request.POST.items())
        for param in params:
            if param.startswith('key_'):
                key = smart_str(param,'utf-8',False)[4:]
                value = request.POST[param]
                for setting in allsettings:
                    if key == setting.key:
                        if setting.value != value:
                            setting.value = value
                            setting.save()

        # Handle checkboxes
        for setting in allsettings:
            if setting.type == 'check':
                if not request.POST.__contains__('key_' + setting.key):
                    setting.value = '0'
                    setting.save()

        ConfigCache.refresh()
        allsettings = ConfigSetting.objects.all();

    data = {'settings': allsettings}
    for setting in allsettings:
        if setting.type == 'check':
            data[setting.key.replace('.','_')] = setting.value == '1'
        else:
            data[setting.key.replace('.','_')] = setting.value

    return render_to_response('configs.html', data, context_instance=RequestContext(request))

def home(request):
    data = {'branches': Branch.objects.all()}
    return render_to_response('home.html', data, context_instance=RequestContext(request))


def manifest(request, release_id):
    release = Release.objects.get(id=release_id)
    release.release_notes = release.release_notes.replace('\n','<br/>');
    manifest = []
    for story in release.stories.all():
        deployables = DeployableObject.objects.filter(pending_stories=story)
        dep_objects = DeployableObject.objects.filter(released_stories=story)
        deployables.select_related()
        dep_objects.select_related()
        manifest += list(deployables)
        manifest += list(dep_objects)

    manifest.sort(key=lambda object: object.type+object.filename)
    data = {'release': release, 'manifest': manifest}
    return render_to_response('release_manifest.html', data, context_instance=RequestContext(request))


def releases(request):
    unreleased = Release.objects.filter(released__exact=False)

    data = {'unreleased_list': unreleased, 'branches': Branch.objects.all()}
    return render_to_response('releases.html', data, context_instance=RequestContext(request))

def release(request, release_id):
    release = Release.objects.get(id=release_id)

    if request.method == u'GET' and request.GET.__contains__('remove_story_id'):
        story = Story.objects.get(id=request.GET['remove_story_id'])
        release.stories.remove(story)
        release.save()
        
    if request.method == u'POST' and request.POST.__contains__('releaseNotes'):
        release.release_notes = request.POST['releaseNotes']
        release.save()

    stories = Story.objects.all().order_by('rally_id', 'name')

    data = {'release': release, 'avail_stories': stories}
    return render_to_response('release.html', data, context_instance=RequestContext(request))

def unreleased(request, repo_name, branch_name):
    branch = Branch.objects.get(repo__name=repo_name,name=branch_name)

    endDate = date.today()
    startDate = endDate + timedelta(days=-42)
    if request.method == u'GET' and request.GET.__contains__('startDate'):
        startDate =  datetime.strptime(request.GET['startDate'],"%m/%d/%Y")
    if request.method == u'GET' and request.GET.__contains__('endDate'):
        endDate = datetime.strptime(request.GET['endDate'],"%m/%d/%Y")
    endDate = endDate + timedelta(days=1)

    deltas = Delta.objects.exclude(object__release_status='r').filter(object__branch=branch).filter(commit__date_added__gte = startDate).filter(commit__date_added__lte = endDate).order_by('object__type','object__filename','object__el_type','object__el_subtype','object__el_name','commit__date_added')
    deltas.select_related()
    objects = []
    deltaMap = {}
    for delta in deltas.all():
        changelog = deltaMap.get(delta.object)
        if changelog:
            tmpChangelog = changelog.replace('&#x21B7;','')
            if not tmpChangelog.endswith(delta.getDeltaType()):
                changelog += ', ' + delta.getDeltaType();
            else:
                changelog += '&#x21B7;'
            deltaMap[delta.object] = changelog
        else:
            objects.append(delta.object)
            deltaMap[delta.object] = delta.getDeltaType()

    data = {'branch_name': branch_name, 'repo_name': branch.repo.name, 'objects': objects, 'startDate': startDate, 'endDate': endDate, 'deltaMap': deltaMap, 'namestl': namestl }
    return render_to_response('unreleased.html', data, context_instance=RequestContext(request))

def object(request, object_id):
    object = DeployableObject.objects.get(id=object_id)
    deltas = Delta.objects.filter(object__filename=object.filename).order_by('commit__branch__name','-commit__date_added')
    data = {'object': object, 'deltas': deltas}
    return render_to_response('object.html', data, context_instance=RequestContext(request))

def stories(request):
    if request.method == u'GET' and request.GET.__contains__('delete'):
        story = Story.objects.get(id=request.GET['delete'])
        objects = DeployableObject.objects.filter(pending_stories=story)
        for object in objects:
            object.pending_stories.remove(story)
            object.save()
        story.delete()

    if request.method == u'GET' and request.GET.__contains__('refresh'):
        projectList = ConfigCache.get_config_value('rally.pickedprojects')
        if len(projectList) > 0:
            rallyStories = get_stories(projectList.split(';'))
            dbstories = Story.objects.filter(rally_id__in=rallyStories.keys())
            dbStoryMap = {}
            for dbstory in dbstories:
                dbStoryMap[dbstory.rally_id] = dbstory

            for story in rallyStories.values():
                dbstory = story
                if story.rally_id in dbStoryMap:
                    # Override with database version if it exists
                    dbstory = dbStoryMap[story.rally_id]
                    dbstory.name = story.name
                dbstory.sprint = story.sprint
                dbstory.save()

    stories = Story.objects.all().order_by('sprint', 'rally_id', 'name')
    stories.select_related()
    data = {'stories': stories, 'rally_refresh' : ConfigCache.get_config_value('rally.enabled') == '1'}
    return render_to_response('stories.html', data, context_instance=RequestContext(request))

def instory(request, story_id):
    story = Story.objects.get(id=story_id)
    branches = []
    dep_branches = []
    
    if request.method == u'GET' and request.GET.__contains__('remove'):
        obj = DeployableObject.objects.get(id=request.GET['assoc'])
        obj.pending_stories.remove(story)
        obj.save()

    if request.method == u'GET' and request.GET.__contains__('release'):
        branch = Branch.objects.get(name=request.GET['release'])
        story.done_on_branches.add(branch)
        objects = DeployableObject.objects.filter(pending_stories=story, branch=branch)
        for object in objects:
            object.pending_stories.remove(story)
            object.released_stories.add(story)
            if (len(object.pending_stories.all()) == 0):
                object.release_status = 'r';
            object.save()
        translations = DeployableTranslation.objects.filter(pending_stories=story, branch=branch)
        for trans in translations:
            trans.pending_stories.remove(story)
            trans.released_stories.add(story)
            if (len(trans.pending_stories.all()) == 0):
                trans.release_status = 'r';
            trans.save()
        story.save()

    objects = DeployableObject.objects.filter(pending_stories=story).order_by('branch__name', 'type','filename','el_type','el_subtype','el_name')
    objects.select_related()

    translations = DeployableTranslation.objects.filter(pending_stories=story).order_by('branch__name', 'label','locale')
    translations.select_related()

    for obj in objects:
        if obj.branch not in branches:
            branches.append(obj.branch)
    for trans in translations:
        if trans.branch not in branches:
            branches.append(trans.branch)

    dep_objects = DeployableObject.objects.filter(released_stories=story).order_by('branch__name', 'type','filename','el_type','el_subtype','el_name')
    dep_objects.select_related()

    dep_translations = DeployableTranslation.objects.filter(released_stories=story).order_by('branch__name', 'label','locale')
    dep_translations.select_related()

    for obj in dep_objects:
        if obj.branch not in dep_branches:
            dep_branches.append(obj.branch)
    for trans in dep_translations:
        if trans.branch not in dep_branches:
            dep_branches.append(trans.branch)

    data = {'story': story, 'objects': objects, 'dep_objects': dep_objects, 'translations': translations, 'dep_translations': dep_translations, 'branches': branches, 'dep_branches': dep_branches}
    if request.method == u'GET' and request.GET.__contains__('branch_name'):
        data['branch_name'] = request.GET['branch_name']
        data['repo_name'] = request.GET['repo_name']

    return render_to_response('in_story.html', data, context_instance=RequestContext(request))

def rally_projects(request):
    if request.method == u'GET' and request.GET.__contains__('chkProject'):
         pickedProjs = request.GET.getlist('chkProject')
         isFirst = True
         projectConfValue = ''
         for p in pickedProjs:
            if not isFirst:
                projectConfValue = projectConfValue + ';'
            isFirst = False
            projectConfValue = projectConfValue + p

         ConfigCache.store_config_value('rally.pickedprojects', projectConfValue)
         return redirect('/configs/')

    projects = get_projects(True)

    data = {'projects': projects}
    return render_to_response('rally_projects.html', data, context_instance=RequestContext(request))
