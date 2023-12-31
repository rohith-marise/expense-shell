log=/tmp/expense.log

magenta="\e[35m"
red="\e[31m"
white="\e[0m"
green="\e[32m"
mysql_passwd=$1

fun_status_check() {
  if [ $? -ne 0 ]; then
    echo -e "${red} Failed ${white}"
    exit 1
  else
    echo -e "${green} Success ${white}"
  fi
}
func_disabling_module() {
  echo -e "${magenta}>>>> Disabling ${package} default version <<<<${white}"
  dnf module disable "${package}" -y &>>${log}
  fun_status_check
}

func_passwd_auth() {
  if [ -z ${mysql_passwd} ]; then
    echo -e "${red}Password Missing ${white}"
    exit 2
  fi
}

func_install_package() {
  echo -e "${magenta}>>>> Installing ${package} <<<<${white}"
  dnf install ${package} -y &>>${log}
  fun_status_check
}

func_Download_app_code() {
  echo -e "${magenta}>>>> Downloading ${component} Application content <<<<${white}"
  curl -o /tmp/${component}.zip https://expense-artifacts.s3.amazonaws.com/${component}.zip &>>${log}
  fun_status_check
}

func_start_service() {
  echo -e "${magenta}>>>> Starting ${service} service <<<<${white}"
  systemctl enable "${service}" &>>${log}
  systemctl restart "${service}" &>>${log}
  fun_status_check
}
func_mysql() {
  func_passwd_auth
  if [ ${component} == "backend" ]; then
    package=mysql
    func_disabling_module
  fi

  echo -e "${magenta}>>>> Setup the MySQL5.7 repo file <<<<${white}"
  cp mysql.repo /etc/yum.repos.d/mysql.repo &>>${log}
  fun_status_check

  echo -e "${magenta}>>>> Installing MYSQL <<<<${white}"
  dnf install mysql-community-server -y &>>${log}
  fun_status_check

  service=mysqld
  func_start_service

  echo -e "${magenta}>>>> User & Password Setup <<<<${white}"
  mysql_secure_installation --set-root-pass ${mysql_passwd} &>>${log}
  fun_status_check

}

func_frontend() {
  if [ ${component} == "frontend" ]; then
      package=nginx
  fi
  func_install_package

  echo -e "${magenta}>>>> Adding reverse proxy configuration file <<<<${white}"
  cp expense.conf /etc/nginx/default.d/expense.conf &>>${log}
  fun_status_check

  echo -e "${magenta}>>>> Removing old HTML content <<<<${white}"
  rm -rf /usr/share/nginx/html/* &>>${log}
  fun_status_check

  func_Download_app_code

  echo -e "${magenta}>>>> Extracting the Application content <<<<${white}"
  cd /usr/share/nginx/html &>>${log}
  unzip /tmp/frontend.zip &>>${log}
  fun_status_check

  service=nginx
  func_start_service
}

func_backend() {
  func_passwd_auth

  if [ ${component} == "backend" ]; then
    package=nodejs
    func_disabling_module
  fi

  echo -e "${magenta}>>>> Enabling Nodejs 18 version <<<<${white}"
  dnf module enable nodejs:18 -y &>>${log}
  fun_status_check

  func_install_package

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

  if [ ! -d /app ]; then
    echo -e "${magenta}>>>> Creating Expense app directory <<<<${white}"
    mkdir /app &>>${log}
    fun_status_check
  fi

  func_Download_app_code

  echo -e "${magenta}>>>> Extracting the Application content <<<<${white}"
  cd /app &>>${log}
  unzip /tmp/backend.zip &>>${log}
  fun_status_check

  echo -e "${magenta}>>>> Installing the Nodejs dependencies <<<<${white}"
  npm install &>>${log}
  fun_status_check

  package=mysql

  func_install_package

  echo -e "${magenta}>>>> Load schema <<<<${white}"
  mysql -h mysql-dev.devrohiops.online -uroot -p${mysql_passwd} < /app/schema/backend.sql  &>>${log}
  fun_status_check

  systemctl daemon-reload &>>${log}
  service=backend
  func_start_service

}