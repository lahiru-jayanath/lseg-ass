#! /bin/bash

DB_URL="terraform-20210213223339257700000001.cuoyovqvitew.us-east-1.rds.amazonaws.com"
DB_USER="foo"
DB_PASS="foobarbaz"
DB="app_status_db"
TABLE="app_status_tb"
sudo ssh -i /opt/id_rsa  -o StrictHostKeyChecking=no ec2-user@172.16.10.15 "sudo /bin/systemctl -q is-active httpd"

status=$?

status_value=" "

status_code=" "

if [ "$status" == 0 ]; then
   status_value="service is up and running"
else
    status_value="service is down and started it again"
   sudo ssh -i /opt/id_rsa -o StrictHostKeyChecking=no ec2-user@172.16.10.15 "sudo /bin/systemctl start httpd"
   echo "HOST : 172.16.10.15 | ALERT SERVICE IS DOWN AND STARTED IT AGAIN" | sendmail myemail@domain.com
fi

url="http://172.16.10.15/"

response=$(curl -s -w "%{http_code}" $url)

http_code=$(tail -n1 <<< "$response")  # get the last line

content=$(sed '$ d' <<< "$response")   # get all but the last line which contains the status code

      if [[ $code != 200  ]] ;
      then

              status_code=$http_code

      else
              status_code=$http_code
        echo "HOST : 172.16.10.15 | STATUS $http_code | MESG SERVER IS UNHEALTHY" | sendmail myemail@domain.com
      fi

echo "$content"
echo $status_code
echo $status_value

mysql --host=$DB_URL --user=$DB_USER --password=$DB_PASS $DB << EOF
INSERT INTO $TABLE (\`status_code\`, \`status_value\`, \`content\`) VALUES ("$status_code", "$status_value","$content");
EOF

exit	  
	  