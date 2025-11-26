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

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "disabling nodejs module"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "enabling nodejs 20 module"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "installing nodejs"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "adding roboshop user"
else
    echo -e "$y INFO:: roboshop user already exists, skipping user creation $n" | tee -a $LOGFILE
fi

mkdir /app &>>$LOGFILE
VALIDATE $? "creating application directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOGFILE
VALIDATE $? "downloading user application code"

rm -rf /app/* &>>$LOGFILE
VALIDATE $? "removing old application content"

cd /app 
unzip /tmp/user.zip &>>$LOGFILE
VALIDATE $? "extracting user application code"

npm install &>>$LOGFILE
VALIDATE $? "installing user application dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOGFILE
VALIDATE $? "copying user service file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "reloading systemd services"

systemctl enable user &>>$LOGFILE
systemctl start user 
VALIDATE $? "starting user service"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
