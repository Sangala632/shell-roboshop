#!/bin/bash
USERID=$(id -u)
r="\e[31m"
g="\e[32m"
y="\e[33m"
n="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE="$LOGES_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "script started executed at: $(date)" &>>$LOGFILE
if [ $USERID -ne 0 ]
then 
    echo -e "$r ERROR:: Please run this script with root access $n" | tee -a $LOGFILE
    exit 1
else
    echo "You are running with root access" | tee -a $LOGFILE
fi

VALIDATE() {
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is ... $g SUCCESS $n" | tee -a $LOGFILE
    else
        echo -e "$2 is ... $r FAILURE $n" | tee -a $LOGFILE
        exit 1
    fi
}

dnf module disable redis -y &>>$LOGFILE
VALIDATE $? "disabling redis module"

dnf module enable redis:7 -y &>>$LOGFILE
VALIDATE $? "enabling redis 7 module"

dnf install redis -y &>>$LOGFILE
VALIDATE $? "installing redis"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf
VALIDATE $? "allowing remote connections in redis config file"

ed -i 's/yes/no/g' /etc/redis/redis.conf   
VALIDATE $? "disabling redis protected mode"

systemctl enable redis &>>$LOGFILE
VALIDATE $? "enabling redis service"

systemctl start redis &>>$LOGFILE
VALIDATE $? "starting redis service"




