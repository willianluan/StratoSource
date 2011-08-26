from django.conf.urls.defaults import *

# Uncomment the next two lines to enable the admin:
from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    # Example:
    # (r'^stratosource/', include('stratosource.admin.urls')),

    # Uncomment the admin/doc line below to enable admin documentation:
    # (r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    #(r'^admin/', include(admin.site.urls)),


    (r'^$', 'stratosource.user.views.home'),
    (r'^configs/', 'stratosource.user.views.configs'),
    (r'^rally_projects/', 'stratosource.user.views.rally_projects'),
    (r'^manifest/(.+)$', 'stratosource.user.views.manifest'),
    (r'^releases', 'stratosource.user.views.releases'),
    (r'^release/(.+)$', 'stratosource.user.views.release'),
    (r'^unreleased/(.+)/(.+)$', 'stratosource.user.views.unreleased'),
    (r'^object/(\d+)$', 'stratosource.user.views.object'),
    (r'^stories', 'stratosource.user.views.stories'),
    (r'^instory/(\d+)$', 'stratosource.user.views.instory'),
    (r'^ajax/releases', 'stratosource.user.ajax.releases'),
    (r'^ajax/createrelease', 'stratosource.user.ajax.createrelease'),
    (r'^ajax/deleterelease', 'stratosource.user.ajax.deleterelease'),
    (r'^ajax/markreleased', 'stratosource.user.ajax.markreleased'),
    (r'^ajax/getstories', 'stratosource.user.ajax.getstories'),
    (r'^ajax/getsprints', 'stratosource.user.ajax.getsprints'),
    (r'^ajax/addtostory', 'stratosource.user.ajax.addtostory'),
    (r'^ajax/addstoriestorelease', 'stratosource.user.ajax.addstoriestorelease'),
    (r'^ajax/updatereleasedate', 'stratosource.user.ajax.updatereleasedate'),
    (r'^ajax/ignoreitem/(\d+)$', 'stratosource.user.ajax.ignoreitem'),
    (r'^ajax/ignoreselected', 'stratosource.user.ajax.ignoreselected'),
    (r'^ajax/ignoretranslation/(\d+)$', 'stratosource.user.ajax.ignoretranslation'),

    (r'^repos/', 'stratosource.admin.views.repos'),
    (r'^branches/(\d+)$', 'stratosource.admin.views.branches'),
    (r'^commits/(\d+)$', 'stratosource.admin.views.commits'),
    (r'^commit/(\d+)$', 'stratosource.admin.views.commit'),

    (r'^csmedia/(?P<path>.*)$', 'django.views.static.serve',
        {'document_root': '/usr/django/stratosource/csmedia'}),

    # admin menu support
    (r'^admin/', 'stratosource.user.admin_views.adminMenu'),
    (r'^newbranch/', 'stratosource.user.admin_views.newbranch'),
    (r'^editbranch/(\d+)$', 'stratosource.user.admin_views.editbranch'),
    (r'^repo_admin_form_action', 'stratosource.user.admin_views.repo_form_action'),
    (r'^branch_admin_form_action', 'stratosource.user.admin_views.branch_form_action'),
    (r'^newrepo/', 'stratosource.user.admin_views.newrepo'),
    (r'^editrepo/(\d+)$', 'stratosource.user.admin_views.editrepo'),
    (r'^repo_admin_form_action', 'stratosource.user.admin_views.repo_form_action'),
    
)
