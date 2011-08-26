#
# Script invoked by cron to process a snapshot
# arg1 is the repo name
# arg2 is the branch name
#

cd /usr/django
./pre-cronjob.sh $1 $2

cd /usr/django/stratosource
python manage.py download $1 $2
python manage.py commit  $1 $2
python manage.py sfdiff $1 $2

cd /usr/django
./post-cronjob.sh $1 $2

