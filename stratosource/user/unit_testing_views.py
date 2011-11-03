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

from django.template import RequestContext
from django.shortcuts import render_to_response, redirect
from stratosource.admin.models import UnitTestRun, UnitTestRunResult, UnitTestSchedule
import logging

logger = logging.getLogger('console')

def admin(request):
    data = {'schedules': UnitTestSchedule.objects.all()}
    return render_to_response('unit_test_config.html', data, context_instance=RequestContext(request))

def results(request):
    runs = UnitTestRun.objects.all().order_by('-batch_time', 'class_name')[:200]
    runs.select_related()
    
    for run in runs:
        if run.failures == 0:
            if run.failures == 0:
                run.outcome = str(run.tests) + ' Tests Passed'
            if run.tests == 0:
                run.outcome = 'No Results'
        else:
            run.outcome = str(run.failures) + ' of ' + str(run.tests) + ' Tests Failed'

    data = {'testruns': runs}
    return render_to_response('unit_testing_results.html', data, context_instance=RequestContext(request))

def result(request, run_id):
    run = UnitTestRun.objects.get(id=run_id)
    results = UnitTestRunResult.objects.filter(test_run=run)
    
    for result in results:
        if result.end_time == result.start_time:
            result.runtime = '<1s'
        else:
            td = result.end_time - result.start_time
            runtime = (td.microseconds + (td.seconds + td.days * 24 * 3600) * 10**6) / 10**6
            result.runtime = str(runtime) + 's'
        

    data = {'run': run, 'results': results}
    return render_to_response('unit_testing_result.html', data, context_instance=RequestContext(request))


