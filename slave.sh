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
#Останавливаем PostgreSQL для дальнейшей работы
service postgresql stop
#Добавим настройки в конфигурационный файл Slave
sed -i “s/#listen_addresses = 'localhost'/ listen_addresses = '*'/” /etc/postgresql/13/main/postgresql.conf
#Удаляем данные из рабочей директории PostgreSQL и зайдем под пользователем postgres
rm -R /var/lib/postgresql/13/main/
su - postgres -c "pg_basebackup -P -R -X stream -c fast -h 192.168.20.2 -U replicacant -D /var/lib/postgresql/13/main/"
#Создаем файл recovery.conf и записываем:
echo " standby_mode = 'on'" | tee -a /var/lib/postgresql/13/main/recovery.conf
echo "standby_mode = 'on'" | tee -a /var/lib/postgresql/13/main/recovery.conf
echo "primary_conninfo = 'user=replicant password=123456 host=192.168.20.2 port=5432 sslmode=prefer sslcompression=0 krbsrvname=postgres target_session_attrs=any'" | tee -a /var/lib/postgresql/13/main/recovery.conf
echo "trigger_file = '/tmp/to_master'" | tee -a /var/lib/postgresql/13/main/recovery.conf
#Отредактируем файл pg_hba.conf
sed  -i '/host    replication/d' /etc/postgresql/13/main/pg_hba.conf
echo "host    replication     replica             192.168.20.1/24                 md5" | tee -a /etc/postgresql/13/main/pg_hba.conf
#Запускаем PostgreSQL
service postgresql start
