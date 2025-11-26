#!/bin/bash

START_TIME=$(date +%s)
cartID=$(id -u)
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
if [ $cartID -ne 0 ]
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
    cartadd --system --home /app --shell /sbin/nologin --comment "roboshop system cart" roboshop
    VALIDATE $? "adding roboshop cart"
else
    echo -e "$y INFO:: roboshop cart already exists, skipping cart creation $n" | tee -a $LOGFILE
fi

mkdir /app &>>$LOGFILE
VALIDATE $? "creating application directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOGFILE
VALIDATE $? "downloading cart application code"

rm -rf /app/* &>>$LOGFILE
VALIDATE $? "removing old application content"

cd /app 
unzip /tmp/cart.zip &>>$LOGFILE
VALIDATE $? "extracting cart application code"

npm install &>>$LOGFILE
VALIDATE $? "installing cart application dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOGFILE
VALIDATE $? "copying cart service file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "reloading systemd services"

systemctl enable cart &>>$LOGFILE
systemctl start cart 
VALIDATE $? "starting cart service"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
