
from stratosource.admin.models import Repo, Branch, Commit, Delta, DeployableObject, Release, Story
from django.contrib import admin

admin.site.register(Repo)
admin.site.register(Branch)
admin.site.register(Commit)
admin.site.register(Delta)
admin.site.register(DeployableObject)
admin.site.register(Release)
admin.site.register(Story)

