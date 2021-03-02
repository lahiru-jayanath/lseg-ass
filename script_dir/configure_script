#! /bin/bash
  

DB_URL="terraform-20210214145503457300000003.cuoyovqvitew.us-east-1.rds.amazonaws.com"
DB_USER="foo"
DB_PASS="foobarbaz"

### Create database and table 

mysql --host=$DB_URL --user=$DB_USER --password=$DB_PASS << EOF

CREATE DATABASE app_status_db;

USE app_status_db;

CREATE TABLE  app_status_tb (
    id int  NOT NULL AUTO_INCREMENT,
    status_code varchar(50),
    status_value varchar(255),
    content blob,
    date_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id)
);
EOF

### Set Crontab

echo "*/2 * * * * /opt/script_dir/script_one  >/dev/null 2>&1" >> /var/spool/cron/root

echo "*/2 * * * * /opt/script_dir/script_second  >/dev/null 2>&1" >> /var/spool/cron/root

sudo /usr/bin/crontab /var/spool/cron/root
