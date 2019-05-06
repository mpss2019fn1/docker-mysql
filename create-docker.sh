#!/bin/bash

if [ ! -x "$(command -v docker)" ]; then
    echo !! DOCKER IS NOT INSTALLED !!
    exit 1
fi

if [ ! -f page_props.sql ]; then 
    wget -O page_props.sql.gz http://dumps.wikimedia.freemirror.org/enwiki/20190420/enwiki-20190420-page_props.sql.gz
    gunzip page_props.sql.gz
fi

if [ ! -f living_people.csv ]; then
    wget -O living_people.csv https://raw.githubusercontent.com/mpss2019fn1/wikicrawler/master/living_people.csv
fi

docker run --name mysql-mpss2019 -e MYSQL_ROOT_PASSWORD=toor -d -p 3306:3306 mysql:latest
sleep 30

docker exec mysql-mpss2019 mysql -uroot -ptoor -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'toor';"
docker exec mysql-mpss2019 mysql -uroot -ptoor -e "CREATE DATABASE IF NOT EXISTS mpss2019;"
docker exec -i mysql-mpss2019 mysql -uroot -ptoor mpss2019 < page_props.sql

docker exec -i mysql-mpss2019 mysql -uroot -ptoor -e "ALTER TABLE mpss2019.page_props ORDER BY pp_page ASC;"

docker exec mysql-mpss2019 mysql -uroot -ptoor -e "CREATE TABLE mpss2019.living_people (\
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, \
    title VARCHAR(255), \
    page_id INT UNSIGNED, \
    namespace VARCHAR(255), \
    length INT UNSIGNED, \
    touched BIGINT UNSIGNED \
);"
docker cp living_people.csv mysql-mpss2019:/var/lib/mysql/living_people.csv

docker exec -i mysql-mpss2019 bash -c "printf '[mysqld]\nsecure_file_priv=\"\"\n' >> /etc/mysql/conf.d/mysql.cnf"
docker restart mysql-mpss2019
sleep 30

docker exec -i mysql-mpss2019 mysql -uroot -ptoor -e "LOAD DATA INFILE '/var/lib/mysql/living_people.csv' INTO TABLE mpss2019.living_people FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES;"