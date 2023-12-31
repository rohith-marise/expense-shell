log=/tmp/expense.log
magenta="\e[35m"
red="\e[31m"
white="\e[0m"
green="\e[32m"
mysql_passwd=$1

if [ -z ${mysql_passwd} ]; then
  echo -e "${red}Password Missing ${white}"
  exit 2
fi

fun_status_check() {
  if [ $? -ne 0 ]; then
    echo -e "${red} Failed ${white}"
    exit 1
  else
    echo -e "${green} Success ${white}"
  fi
}

echo -e "${magenta}>>>> Disabling Nodejs default version <<<<${white}"
dnf module disable nodejs -y &>>${log}
fun_status_check

echo -e "${magenta}>>>> Enabling Nodejs 18 version <<<<${white}"
dnf module enable nodejs:18 -y &>>${log}
fun_status_check

echo -e "${magenta}>>>> Installing Nodejs <<<<${white}"
dnf install nodejs -y &>>${log}

id expense &>>${log}
if [ $? -ne 0 ]; then
  echo -e "${magenta}>>>> Creating Expense user <<<<${white}"
  useradd expense &>>${log}
  fun_status_check
fi

echo -e "${magenta}>>>> Creating backend service <<<<${white}"
cp backend.service /etc/systemd/system/backend.service &>>${log}
fun_status_check

echo -e "${magenta}>>>> Removing old content <<<<${white}"
rm -rf /app &>>${log}
fun_status_check

if [ ! -d /app]; then
  echo -e "${magenta}>>>> Creating Expense app directory <<<<${white}"
  mkdir /app &>>${log}
  fun_status_check
fi

echo -e "${magenta}>>>> Downloading Application content <<<<${white}"
curl -o /tmp/backend.zip https://expense-artifacts.s3.amazonaws.com/backend.zip
fun_status_check

echo -e "${magenta}>>>> Extracting the Application content <<<<${white}"
cd /app &>>${log}
unzip /tmp/backend.zip &>>${log}
fun_status_check

echo -e "${magenta}>>>> Installing the Nodejs dependencies <<<<${white}"
npm install &>>${log}
fun_status_check

echo -e "${magenta}>>>> Install MySQL client to load schema <<<<${white}"
dnf install mysql -y &>>${log}
fun_status_check

echo -e "${magenta}>>>> Load schema <<<<${white}"
mysql -h 172.31.30.30 -uroot -${mysql_passwd} < /app/schema/backend.sql  &>>${log}
fun_status_check

echo -e "${magenta}>>>> Starting the backend service <<<<${white}"
systemctl daemon-reload &>>${log}
systemctl enable backend &>>${log}
systemctl start backend &>>${log}
fun_status_check


