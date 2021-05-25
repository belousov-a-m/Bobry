#!/bin/bash
#Разрешаем трафик по порту 5432
iptables -A INPUT -p tcp --dport 5432 -j ACCEPT
iptables -A INPUT -p tcp --sport 5432 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 5432 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 5432 -j ACCEPT
#Установка Postgres
apt-get update
apt-get install -y curl gnupg2 
echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" >> /etc/apt/sources.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install -y postgresql
service postgresql restart
#Создание пользователя replica для репликации
psql -U postgres -c "CREATE USER replicant REPLICATION LOGIN CONNECTION LIMIT 2 ENCRYPTED PASSWORD '123456';"
# Настраиваем PostgreSQL через конфигурационный файл
sed -i "s/#listen_addresses = 'localhost'/ listen_addresses = '*'/" /etc/postgresql/13/main/postgresql.conf
sed -i "s/#hot_standby = off/hot_standby = on/" /etc/postgresql/13/main/postgresql.conf
sed -i "s/#wal_level = minimal/wal_level = replica/" /etc/postgresql/13/main/postgresql.conf
sed -i "s/#max_wal_senders = 1/max_wal_senders = 10/" /etc/postgresql/13/main/postgresql.conf
sed -i "s/#wal_keep_segments = 32/wal_keep_segments = 32/" /etc/postgresql/13/main/postgresql.conf
# Настраиваем подключение пользователя для репликации
cp /etc/postgresql/13/main/pg_hba.conf /etc/postgresql/13/main/pg_hba{`date +%s`}.bkp
sed  -i '/host    replication/d' /etc/postgresql/13/main/pg_hba.conf
echo "host    replication     replica             127.0.0.1/32                 md5" | tee -a /etc/postgresql/13/main/pg_hba.conf
echo "host    replication     replica             192.168.20.2/24                 md5" | tee -a /etc/postgresql/13/main/pg_hba.conf
echo "host    replication     replica             192.168.20.3/24                 md5" | tee -a /etc/postgresql/13/main/pg_hba.conf
service postgresql restart
