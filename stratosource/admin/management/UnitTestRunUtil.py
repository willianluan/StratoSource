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

from django.core.mail import send_mail
from django.template import Template, TemplateDoesNotExist, Context
from django.template.loader import get_template
from stratosource.admin.models import UnitTestBatch, UnitTestRun, UnitTestRunResult, UnitTestSchedule, Branch

def email_results(batch, failures, long_runners):
    
    template = get_template('unit_test_results_email.html')
    c = Context({'batch': batch, 'failures': failures, 'long_runners': long_runners})
    
    send_mail(
        'Unit test results for ' + batch.branch.name + ' started at ' + batch.batch_time,
        template.render(c),
        'noreply@domain.com',
        ['user@domain.com'],
        fail_silently=False
    )
    
def processRun(batch_id):
    failures = []
    
    batch = UnitTestBatch.objects.get(id=batch_id)
    batch.runtime = 0
    
    runs = UnitTestRun.objects.get(batch=batch)    
    for run in runs:
        run.runtime = 0
        results = UnitTestRunResult.objects.filter(test_run=run)
        
        for result in resultList:
            # For each result, calculate the time taken - minimum 1 second
            if result.outcome == 'Pass':
                if result.end_time == result.start_time:
                    result.runtime = '1'
                else:
                    td = result.end_time - result.start_time
                    runtime = (td.microseconds + (td.seconds + td.days * 24 * 3600) * 10**6) / 10**6
                    result.runtime = runtime
            else:
                failures.append(result)
                
            # Save the result with time calculated
            result.save()
            # Add the result runtime to the test run
            run.runtime += result.runtime            
            
        # Save the run
        run.save()
        # Add the run's runtime to the batch
        batch.tests += run.tests
        batch.failures += run.failures
        batch.runtime += run.runtime
        
    # Save the batch
    batch.save()
