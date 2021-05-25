#!/bin/bash
#–азрешаем трафик по порту 5432
iptables -A INPUT -p tcp --dport 5432 -j ACCEPT
iptables -A INPUT -p tcp --sport 5432 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 5432 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 5432 -j ACCEPT
#”становка Postgres
apt-get update
apt-get install -y curl gnupg2 
echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" >> /etc/apt/sources.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install -y postgresql
service postgresql restart
#—оздание пользовател€ replica дл€ репликации
psql -U postgres -c "CREATE USER replicant REPLICATION LOGIN CONNECTION LIMIT 2 ENCRYPTED PASSWORD '123456';"
# Ќастраиваем PostgreSQL через конфигурационный файл
sed -i Уs/#listen_addresses = 'localhost'/ listen_addresses = '*'/Ф /etc/postgresql/13/main/postgresql.conf
sed -i Уs/#hot_standby = off/hot_standby = on/Ф /etc/postgresql/13/main/postgresql.conf
sed -i Уs/#wal_level = minimal/wal_level = replica/Ф /etc/postgresql/13/main/postgresql.conf
sed -i Уs/#max_wal_senders = 1/max_wal_senders = 10/Ф /etc/postgresql/13/main/postgresql.conf
sed -i Уs/#wal_keep_segments = 32/wal_keep_segments = 32Ф /etc/postgresql/13/main/postgresql.conf
# Ќастраиваем подключение пользовател€ дл€ репликации
cp /etc/postgresql/13/main/pg_hba.conf /etc/postgresql/13/main/pg_hba{`date +%s`}.bkp
sed  -i '/host    replication/d' /etc/postgresql/13/main/pg_hba.conf
echo "host    replication     replica             127.0.0.1/32                 md5" | tee -a /etc/postgresql/13/main/pg_hba.conf
echo "host    replication     replica             192.168.1.2/24                 md5" | tee -a /etc/postgresql/13/main/pg_hba.conf
echo "host    replication     replica             192.168.20.3/24                 md5" | tee -a /etc/postgresql/13/main/pg_hba.conf
service postgresql restart
