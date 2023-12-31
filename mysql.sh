log=/tmp/expense.log
magenta="\e[35m"
red="\e[31m"
white="\e[0m"
green="\e[32m"
passwd=$1
fun_status_check() {
  if [ $? -ne 0 ]; then
    echo -e "${red} Failed ${white}"
    exit 1
  else
    echo -e "${green} Success ${white}"
  fi
}

echo -e "${magenta}>>>> Disabling default MYSQL version <<<<${white}"
dnf module disable mysql -y
fun_status_check

echo -e "${magenta}>>>> Setup the MySQL5.7 repo file <<<<${white}"
cp mysql.repo /etc/yum.repos.d/mysql.repo
fun_status_check

echo -e "${magenta}>>>> Installing MYSQL <<<<${white}"
dnf install mysql-community-server -y
fun_status_check

echo -e "${magenta}>>>> Starting MySQL service <<<<${white}"
systemctl enable mysqld
systemctl start mysqld
fun_status_check

echo -e "${magenta}>>>> User & Password Setup <<<<${white}"
mysql_secure_installation --set-root-pass ${passwd}
fun_status_check
