#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "script started executed at: $(date)" &>>$LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi


VALIDATE() {
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install python3 gcc python3-devel -y &>>$LOGFILE
VALIDARE $? "INSTALLING python"

id roboshop &>>$LOGFILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "adding roboshop user"
else
    echo -e "$y INFO:: roboshop user already exists, skipping user creation $n" | tee -a $LOGFILE
fi

mkdir /app &>>$LOGFILE
VALIDATE $? "creating application directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOGFILE
VALIDATE $? "downloading payment application code"

rm -rf /app/* &>>$LOGFILE
cd /app 
unzip /tmp/payment.zip &>>$LOGFILE
VALIDATE $? "unzipping the payment file"

pip3 install -r requirements.txt &>>$LOGFILE
VALIDATE $? "installling the dependiecies os payment"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOGFILE
VALIDATE $? "COPYING THE payment servive"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "reloading the payment application"

systemctl enable payment &>>$LOGFILE
VALIDATE $? "enabling the payment application"

systemctl start payment &>>$LOGFILE
VALIDATE $? "starting the payment application"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE





