
import logging
import logging.config
import os
import popen2
import string

__author__="mark"
__date__ ="$Oct 6, 2010 8:41:36 PM$"

def perform_checkin(repodir, zipfile, branch):

    LOG = repodir + '/../checkin.log'

    os.chdir(repodir)

    logging.basicConfig(filename=os.path.join('../checkin.log'), format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    log = logging.getLogger('checkin')
    log.setLevel(logging.DEBUG)

    print 'Starting checking...'
    log.info("Starting checkin")
    log.info("repodir " + repodir)
    log.info("zipfile " + zipfile)
    log.info("branch " + branch)

    print 'checkout'
    os.system('git reset --hard ' + branch + ' >>' + LOG)

    print 'checking deletes'
    log.info("Getting list of deleted files")
    os.system('git reset --hard %s >> %s' % (branch, LOG))
    os.system('rm -rf %s/*' % repodir)
    os.system('unzip -o -qq %s >> %s' % (zipfile, LOG))

    r,w = popen2.popen2("git status")
    rm_list = []
    for line in r:
        line = line.rstrip()
        if 'deleted:' in line:
            ix = string.find(line, 'deleted:') + 10
            path = line[ix:].strip()
            rm_list.append(path)
    r.close()
    w.close()
    log.info("found %d file(s) to remove" % len(rm_list))

    log.info("Resetting repo back to HEAD")
    os.system('git reset --hard %s >> %s' % (branch,LOG))
    os.system('unzip -o -qq %s >> %s' % (zipfile,LOG))

    for name in rm_list:
        os.system('git rm "%s"' % name)
        log.info("Deleted " + name)

    log.info("Laying down changes")

    os.system('git add * >> %s' % LOG)
    os.system('git commit -m "incremental snapshot for %s on `date`" >> %s' % (branch, LOG))
    log.info("Completed checkin")

