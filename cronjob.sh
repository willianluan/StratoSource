#
# Script invoked by cron to process a snapshot
# arg1 is the repo name
# arg2 is the branch name
#

LOG_NAME=/tmp/$1_$2_$(date +%Y%M%d%H%M%S)_pull.log


cd /usr/django >>$LOG_NAME 2>&1
./pre-cronjob.sh $1 $2 >>$LOG_NAME 2>&1
python manage.py storelog $1 $2 $LOG_NAME

cd /usr/django/stratosource >>$LOG_NAME 2>&1
python manage.py download $1 $2 >>$LOG_NAME 2>&1
python manage.py storelog $1 $2 $LOG_NAME

python manage.py commit  $1 $2 >>$LOG_NAME 2>&1
python manage.py storelog $1 $2 $LOG_NAME

python manage.py sfdiff $1 $2 >>$LOG_NAME 2>&1
python manage.py storelog $1 $2 $LOG_NAME

cd /usr/django >>$LOG_NAME 2>&1
./post-cronjob.sh $1 $2 >>$LOG_NAME 2>&1
python manage.py storelog $1 $2 $LOG_NAME
