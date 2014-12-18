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

from stratosource.admin.models import Repo, Branch, Commit, Delta, DeployableObject, Release, Story
from django.contrib import admin

admin.site.register(Repo)
admin.site.register(Branch)
admin.site.register(Commit)
admin.site.register(Delta)
admin.site.register(DeployableObject)
admin.site.register(Release)
admin.site.register(Story)

