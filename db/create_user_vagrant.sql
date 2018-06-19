create user vagrant@localhost identified by 'vagrant';
create user vagrant@192.168.33.1 identified by 'vagrant';
# select User,Host from mysql.user;
grant all on *.* to 'vagrant'@'localhost';
grant all on *.* to 'vagrant'@'192.168.33.1';

