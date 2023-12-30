log=/tmp/expense.log
magenta="\e[35m"
red="\e[31m"
white="\e[0m"
green="\e[32m"

fun_status_check() {
  if [ $? -ne 0 ]; then
    echo -e "${red} Failed ${white}"
    exit 1
  else
    echo -e "${green} Success ${white}"
  fi
}
echo -e "${magenta}>>>> Installing Nginx <<<<${white}"
dnf install nginx -y &>>${log}
fun_status_check

echo -e "${magenta}>>>> Adding reverse proxy configuration file <<<<${white}"
cp expense.conf /etc/nginx/default.d/expense.conf &>>${log}
fun_status_check

echo -e "${magenta}>>>> Starting Nginx service <<<<${white}"
systemctl enable nginx &>>${log}
systemctl start nginx &>>${log}
fun_status_check

echo -e "${magenta}>>>> Removing old HTML content <<<<${white}"
rm -rf /usr/share/nginx/html/* &>>${log}
fun_status_check

echo -e "${magenta}>>>> Downloading Application content <<<<${white}"
curl -o /tmp/frontend.zip https://expense-artifacts.s3.amazonaws.com/frontend.zip &>>${log}
fun_status_check

echo -e "${magenta}>>>> Extracting the Application content <<<<${white}"
cd /usr/share/nginx/html &>>${log}
unzip /tmp/frontend.zip &>>${log}
fun_status_check

echo -e "${magenta}>>>> Restarting the Nginx service <<<<${white}"
systemctl restart nginx &>>${log}
fun_status_check
