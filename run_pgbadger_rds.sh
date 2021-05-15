#!/bin/bash
. ~/.bash_profile
# script to generate pgbadger reports
#Arguments = -i aws-instance-name -r aws-region-name  -c cron_or_not -v
usage()
{
cat << EOF
usage: $0 options
This script will downalod the postgres rds log files and generate pgbadger reports
OPTIONS:
   -h      Show this message
   -i      DBInstanceIdentifier 
   -r      AWS Region 
   -v      Verbose
EOF
}

AWS_INSTANCE=
AWS_REGION=
VERBOSE=
IS_CRON=0
while getopts “hi:r:c::v” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         i)
             AWS_INSTANCE=$OPTARG
             ;;
         r)
             AWS_REGION=$OPTARG
             ;;
         c)
             IS_CRON=$OPTARG
             ;;
         v)
             VERBOSE=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [[ -z $AWS_INSTANCE ]] || [[ -z $AWS_REGION ]] 
then
     usage
     exit 1
fi


# environment variables
#AWS_CREDENTIAL_FILE=~/.aws/aws_credential_file
#export AWS_CREDENTIAL_FILE

# let's put  date in a variable
TODAY=$(date '+%Y-%m-%d')
#YESTERDAY=`/bin/date -d "1 day ago" +\%Y-\%m-\%d`
YESTERDAY=$(date -d "1 day ago" +\%Y-\%m-\%d)

DOWNLOAD_DATE=''

if [ $IS_CRON -eq 0 ]
then
 DOWNLOAD_DATE=$TODAY
else
 DOWNLOAD_DATE=$YESTERDAY
fi

# pgbadger home
PGBADGER_HOME=/home/ec2-user/pgbadger/pgbadger-report/
mkdir -p $PGBADGER_HOME/$AWS_INSTANCE 

#function starts
download_rds_logs_and_generate_html() {

#remove file, if exists
rm -f $PGBADGER_HOME/$AWS_INSTANCE/postgresql.log.$DOWNLOAD_DATE.txt

 #describe and downlowd log files for yesterday
#describe and downlowd log files for yesterday
for filename  in $( aws rds describe-db-log-files --db-instance-identifier $AWS_INSTANCE --region $AWS_REGION |grep error/postgresql |grep $DOWNLOAD_DATE  | awk '{gsub("\"","",$2)} {gsub(",","",$2); print $2}' )
do
 echo $filename
 aws rds download-db-log-file-portion --db-instance-identifier $AWS_INSTANCE --region $AWS_REGION  --starting-token 0 --output text --log-file-name $filename >> $PGBADGER_HOME/$AWS_INSTANCE/postgresql.log.$DOWNLOAD_DATE.txt
 #cd $PGBADGER_HOME/$AWS_INSTANCE
 #ls -ltr
done

# run pgbadger report
cd $PGBADGER_HOME/$AWS_INSTANCE
#ls -ltr
pgbadger --p '%t:%r:%u@%d:[%p]:' postgresql.log.$DOWNLOAD_DATE.txt -o postgresql.log.$DOWNLOAD_DATE.html

# remove log file
rm $PGBADGER_HOME/$AWS_INSTANCE/postgresql.log.$DOWNLOAD_DATE.txt
 return 0
} 
#function ends

#call the function to download log files and generate pgbadger html file
download_rds_logs_and_generate_html $DOWNLOAD_DATE


# Download log files and run pgbadger report

#if [ $IS_CRON -eq 0 ]
#then
# DOWNLOAD_DATE =  $TODAY
# download_rds_logs_and_generate_html $DOWNLOAD_DATE
#else
# DOWNLOAD_DATE =  $YESTERDAY
# download_rds_logs_and_generate_html $DOWNLOAD_DATE
#fi
