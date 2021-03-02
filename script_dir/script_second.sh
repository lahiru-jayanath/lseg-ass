#!/bin/bash
  

sudo mkdir -p /tmp/temp-log

sudo mkdir -p /tmp/temp-content


sudo scp -i /opt/id_rsa  -o StrictHostKeyChecking=no ec2-user@172.16.10.15:/var/log/*  /tmp/temp-log/


sudo scp -i /opt/id_rsa  -o StrictHostKeyChecking=no ec2-user@172.16.10.15:/var/log/*  /tmp/temp-content/


tar -zcvf /tmp/"log-$(date '+%F').tar.gz" /tmp/temp-log/*
          
         
tar -zcvf /tmp/"content-$(date '+%F').tar.gz" /tmp/temp-content/*
         
aws s3 cp /tmp/log-$(date '+%F').tar.gz  s3://s3-my-log-backup/

check_log_upload_status=$?
      
 if [ "$check_log_upload_status" == 0 ]; then
         echo "log  file uploaded" 
         rm -rf /tmp/log-$(date '+%F').tar.gz
    
 else  
         echo "s3 log upload failed"
		 echo "ALERT S3 LOG UPLOAD FAILED" | sendmail myemail@domain.com
  fi     
         
    
aws s3 cp /tmp/content-$(date '+%F').tar.gz  s3://s3-my-log-backup/

check_content_upload_status=$?

  if [ "$check_content_upload_status" == 0 ]; then
           echo "content file uploaded"
          rm -rf /tmp/content-$(date '+%F').tar.gz
   else
           echo "ALERT S3 CONTENT UPLOAD FAILED" | sendmail myemail@domain.com
   fi
