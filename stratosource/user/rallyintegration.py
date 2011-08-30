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
import json
import urllib2
from stratosource.admin.management import ConfigCache
from stratosource.admin.models import Story
from operator import attrgetter
import logging

logger = logging.getLogger('console')

class RallyProject():
    def __init__(self, a_name, a_url, some_children, some_sprints):
        self.name = a_name
        self.url = a_url
        url_pieces = a_url.split('/')
        jsFileName = url_pieces[len(url_pieces) - 1]
        jsFileNameParts = jsFileName.split('.')
        self.id = jsFileNameParts[0]
        self.children = some_children
        self.sprints = some_sprints

def print_proj_tree(pList):
    for p in pList:
        if len(p.children) == 0:
            logger.debug(p.name + ' - ' + p.id + ' (' + str(len(p.sprints)) + ' sprints)')
        else:
            print_proj_tree(p.children)

def find_leaves(pList, level, leaves):
    for p in pList:

        if len(p.children) == 0:
            if not leaves.has_key(p.id) or level > leaves[p.id]:
                leaves[p.id] = level
        else:
            find_leaves(p.children, level + 1, leaves)
    return leaves

def leaf_list(pList, llist):

    for p in pList:
        if len(p.children) == 0:
            llist.append(p)
        else:
            leaf_list(p.children, llist)

    return llist

def load_projects(urllib2, name, projectList):
    projects = []
    if len(name) > 0:
        name = name + ': '
        
    if len(projectList) > 0:
        for project in projectList:
            projectDetailJs = urllib2.urlopen(project['_ref']).read()
            projectDetail = json.loads(projectDetailJs)

            proj = RallyProject(name + projectDetail['Project']['_refObjectName'], projectDetail['Project']['_ref'], load_projects(urllib2, name + projectDetail['Project']['_refObjectName'], projectDetail['Project']['Children']), projectDetail['Project']['Iterations'])
            if len(proj.children) > 0 or len(proj.sprints) > 0:
                projects.append(proj)

    leaves = find_leaves(projects, 0, {})
    for p in projects:
        if  leaves.has_key(p.id) and leaves[p.id] > 0:
            projects.remove(p)

    projects.sort()

    return projects

def connect():
    rally_user = ConfigCache.get_config_value('rally.login')
    rally_pass = ConfigCache.get_config_value('rally.password')

    password_manager = urllib2.HTTPPasswordMgrWithDefaultRealm()
    password_manager.add_password( None, 'https://rally1.rallydev.com/', rally_user, rally_pass )
    auth_handler = urllib2.HTTPBasicAuthHandler(password_manager)
    opener = urllib2.build_opener(auth_handler)
    urllib2.install_opener(opener)

    return urllib2

def get_projects(leaves):
    logger.debug('Start getting projects')
    urllib2 = connect()

    # Get workspace:
    projects = []
    wsjs = urllib2.urlopen('https://rally1.rallydev.com/slm/webservice/1.26/workspace.js').read()
    workspaces = json.loads(wsjs)

    logger.debug('Workspaces returned: ' + str(workspaces['QueryResult']['TotalResultCount']))

    if workspaces['QueryResult']['TotalResultCount'] > 0:
        for ws in workspaces['QueryResult']['Results']:
            logger.debug('Workspace: ' + ws['_refObjectName'] + ' url "' + ws['_ref'] + '"')
            wsDetailsJs = urllib2.urlopen(ws['_ref']).read()
            wsDetails = json.loads(wsDetailsJs)
            projects.extend(load_projects(urllib2, ws['_refObjectName'], wsDetails['Workspace']['Projects']))

    print_proj_tree(projects)
    if leaves:
        return sorted(leaf_list(projects,[]), key=attrgetter('name'))
    
    return projects

def get_stories(projectIds):
    urllib2 = connect()

    stories = {}
    for projId in projectIds:
        url = 'https://rally1.rallydev.com/slm/webservice/1.26/project/' + projId + '.js'
        logger.debug('Fetching url ' + url)
        pcprojjson = urllib2.urlopen(url).read()
        pcproj = json.loads(pcprojjson)
        logger.debug('Processing project ' + pcproj['Project']['_refObjectName'])
        pcproj['Project']['Iterations'].sort()
        for iteration in pcproj['Project']['Iterations']:
            sprintName = iteration['_refObjectName']
            logger.debug('Processing sprint ' + sprintName)

            sprdet = urllib2.urlopen(iteration['_ref']).read()
            sprint = json.loads(sprdet)
            hist = urllib2.urlopen(sprint['Iteration']['RevisionHistory']['_ref']).read()
            history = json.loads(hist)

            revisions = list()
            for rev in history['RevisionHistory']['Revisions']:
                revisions.append(rev)

            revisions.reverse()
            for rev in revisions:
                if rev['Description'].startswith('Scheduled ') or rev['Description'].startswith('Unscheduled '):
                    ral_id = rev['Description'].split('[')[1].split(']')[0].partition(':')[0]
                    ral_name = rev['Description'][rev['Description'].find(':') + 2:150]
                    if ral_name.endswith(']'):
                        ral_name = ral_name[0:ral_name.rfind(']')]
                    if rev['Description'].startswith('Scheduled '):
                        logger.debug('Add [' + ral_id + '] ' + ral_name)
                        if ral_id not in stories:
                            story = Story()
                            story.rally_id = ral_id
                            story.name = ral_name
                            story.sprint = sprintName
                            stories[ral_id] = story
                    if rev['Description'].startswith('Unscheduled '):
                        if ral_id in stories:
                            story = stories[ral_id]
                            if story.sprint == sprintName:
                                story.sprint = ''

    return stories
