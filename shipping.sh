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

mkdir -p $LOGS_FOLDER
echo "script started executed at: $(date)" &>>$LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

echo "enter the mysql root password"
read -s mysql_root_password

VALIDATE() {
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install maven -y &>>$LOGFILE
VALIDARE $? "INSTALLING maven"

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

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOGFILE
VALIDATE $? "downloading user application code"

rm -rf /app/* &>>$LOGFILE
cd /app 
unzip /tmp/shipping.zip &>>$LOGFILE
VALIDATE $? "unzipping the shipping file"

mvn clean package &>>$LOGFILE
VALIDATE $? "installing dependecies"

mv target/shipping-1.0.jar shipping.jar &>>$LOGFILE
VALIDATE $? "moving and renaming the jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOGFILE

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "reloading the shipping"

systemctl enable shipping &>>$LOGFILE
VALIDATE $? "enabling the shipping"

systemctl start shipping &>>$LOGFILE
VALIDATE $? "starting the shipping"

dnf install mysql -y  &>>$LOGFILE
VALIDATE $? "installing the mysql"

mysql -h mysql.hellodevsecops.space -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.hellodevsecops.space  -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOGFILE
    mysql -h mysql.hellodevsecops.space  -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOGFILE
    mysql -h mysql.hellodevsecops.space  -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOGFILE
    VALIDATE $? "loading data into mysql"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOGFILE
VALIDATE $? "Restart shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE


