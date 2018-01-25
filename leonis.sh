#! /bin/bash

current=${PWD##*/}

if [ -d "$1" ]; then
    echo "Press ^C at any time to quit.";
    read -p "project name: ($current) " name;
    if [ "$name" == "" ]; then
      name=$current;
    fi
    path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    name=$1;
fi

cat > ./Vagrantfile <<DELIM
# -*- mode: ruby -*-
# vi: set ft=ruby :

\$script = <<SCRIPT
apt-get update && apt-get -y dist-upgrade
timedatectl set-timezone America/Sao_Paulo
add-apt-repository -y ppa:nginx/development
add-apt-repository -y ppa:ondrej/php
apt-get update
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get install -y nginx php7.1-fpm php7.1-curl php7.1-mysql php7.1-cli mysql-server-5.7 sendmail
cat <<EOT >> /etc/nginx/sites-available/site.conf
server {
  listen 80;\n
  server_name $name.local;\n
  root /var/www;
  index index.php index.html\n
  location / {
  }
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    include fastcgi_params;
    fastcgi_pass unix:/run/php/php7.1-fpm.sock;
    fastcgi_param SCRIPT_FILENAME /var/www$fastcgi_script_name;
  }
}
EOT
sudo chmod 644 /etc/nginx/sites-available/site.conf
sudo ln -s /etc/nginx/sites-available/site.conf /etc/nginx/sites-enabled/site.conf
sudo service nginx restart
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
cat <<EOT >> wp-cli.yml
path: /var/www
url: http://$name.local\n
core download:
    locale: pt_BR\n
config create:
    dbname: $name
    dbuser: root
    dbpass: root
    extra-php: |
        define( 'WP_DEBUG', true );\n
core install:
    title: ${name^}
    admin_user: $name
    admin_password: $name
    admin_email: $name@$name.local
EOT
chown vagrant:vagrant wp-cli.yml
sudo chown vagrant:vagrant /var/www
sudo -u vagrant -i -- wp core download
sudo -u vagrant -i -- wp config create
sudo -u vagrant -i -- wp db create
sudo -u vagrant -i -- wp core install --skip-email
sudo -u vagrant -i -- wp scaffold _s $name --activate
sudo -u vagrant -i -- wp plugin delete \$(wp plugin list --status=inactive --field=name)
sudo -u vagrant -i -- wp theme delete \$(wp theme list --status=inactive --field=name)
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.synced_folder ".", "/var/www/wp-content/themes/$name"
  config.vm.provision "shell", inline: \$script
end
DELIM

#
#sudo -u vagrant -i -- wp theme delete $(wp theme list --status=inactive --field=name)


#echo "name is: $name";
# mkdir $name;
# cd $name;
# touch Vagrantfile;
