#! /bin/bash

current=${PWD}
currentname=${PWD##*/}

echo "Press ^C at any time to quit.";

if [ -n "$1" ]; then
    read -p "project name: ($currentname) " name;
    if [ -z "$name" ]; then
      name=$currentname;
    fi
    path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    name=$1;
fi

server_name="$server_name"
read -p "server name: ($server_name) " server_name_read;
if [ -n "$server_name_read" ]; then
  server_name=$server_name_read;
fi

admin_user=$name
read -p "admin user: ($admin_user) " admin_user_read;
if [ -n "$admin_user_read" ]; then
  admin_user=$admin_user_read;
fi

admin_password=$name
read -p "admin password: ($admin_password) " admin_password_read;
if [ -n "$admin_password_read" ]; then
  admin_password=$admin_password_read;
fi

admin_email=$name@$server_name
read -p "admin email: ($admin_email) " admin_email_read;
if [ -n "$admin_email_read" ]; then
  admin_email=$admin_email_read;
fi

title=${name^}
read -p "project title: ($title) " title_read;
if [ -n "$title_read" ]; then
  title=$title_read;
fi

phpversion="$phpversion"
read -p "php version: ($phpversion) " phpversion_read;
if [ -n "$phpversion_read" ]; then
  phpversion=$phpversion_read;
fi

author="Fervidum"
read -p "author: ($author) " author_read;
if [ -n "$author_read" ]; then
  author=$author_read;
fi

author_uri="https://fervidum.github.io/"
read -p "author uri: ($author_uri) " author_uri_read;
if [ -n "$author_uri_read" ]; then
  author_uri=$author_uri_read;
fi

#"/home/username/vagrant/"
vagrant_folder="."
read -p "vagrant folder: ($vagrant_folder/) " vagrant_folder_read;
if [ -n "$vagrant_folder_read" ]; then
  vagrant_folder=$vagrant_folder_read;
fi

#user_email="email@email"
#user_name="First last"

#sudo apt-get update && sudo apt-get -y dist-upgrade
#sudo timedatectl set-timezone America/Sao_Paulo
#sudo add-apt-repository -y ppa:nginx/development
#sudo add-apt-repository -y ppa:ondrej/php
#sudo apt-get update

#php$phpalt-curl sendmail
#php$phpalt-fpm php$phpalt-mysql php$phpversion-cli mysql-server-5.7 git

#git config --global user.email "$user_email"
#git config --global user.name "$user_name"

rm -rf .git

git init -q
rm -f README.md
echo "# $title" >> README.md
git add README.md
git commit -m "First commit" -q
git checkout -b develop -q

theme_path=wp-content/themes/$name

rm -f $theme_path/style.css
cat <<EOT >> $theme_path/style.css
/*!
Theme Name:   $title
Author:       $author
Author URI:   $author_uri
Version:      1.0.0
Text Domain:  $name
*/

EOT

rm -f $theme_path/index.php
cat <<EOT >> $theme_path/index.php
<?php
/**
 * The main template file.
 *
 * This is the most generic template file in a WordPress theme
 *
 * @package $name
 */

get_header(); ?>


<?php
get_footer();
EOT

rm -f $theme_path/header.php
cat <<EOT >> $theme_path/header.php
<?php
/**
 * The header for our theme.
 *
 * Displays all of the <head> section and everything up till <div id="content">
 *
 * @package $name
 */

?><!doctype html>
<html <?php language_attributes(); ?>>
	<head>
		<meta charset="<?php bloginfo( 'charset' ); ?>">

		<?php wp_head(); ?>
	</head>
	<body>
EOT

rm -f $theme_path/footer.php
cat <<EOT >> $theme_path/footer.php
<?php
/**
 * The template for displaying the footer.
 *
 * Contains the closing of the #content div and all content after
 *
 * @package $name
 */

?>

		</div><!-- #content -->

		<?php wp_footer(); ?>

	</body>
</html>
EOT

rm -f .gitignore
cat <<EOT >> .gitignore
# Add any directories, files, or patterns you don't want to be tracked by version control
/wp*

# Un-ignore plugin and theme
!/wp-content
/wp-content/*

!/wp-content/themes
/wp-content/themes/*
!/wp-content/plugins
/wp-content/plugins/*
!/wp-content/plugins/*.zip
!/wp-content/themes/*.zip
!/wp-content/themes/$name

!/wp-cli.*
/*.php
/*.txt
/*.html
/*.sql

/node_modules
/vendor

.DS_Store
Thumbs.db
desktop.ini

/.vagrant
/*.log
EOT

rm -f .editorconfig
cat <<EOT >> .editorconfig
# This file is for unifying the coding style for different editors and IDEs
# editorconfig.org

# WordPress Coding Standards
# https://make.wordpress.org/core/handbook/coding-standards/

root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = tab
indent_size = 4

[{.jshintrc,*.json,*.yml}]
indent_style = space
indent_size = 2

[{*.txt,wp-config-sample.php}]
end_of_line = crlf
EOT

rm -f .jshintrc
cat <<EOT >> .jshintrc
{
    "browser": true,
    "globals": {
        "jQuery": false
    }
}
EOT

if [ "$vagrant_folder" != "." ]; then
  #echo "mkdir $vagrant_folder"
  vagrant_folder="$vagrant_folder/$name"
  if [ ! -d $vagrant_folder ]; then
    mkdir $vagrant_folder
  fi
fi

cat > $vagrant_folder/Vagrantfile <<DELIM
# -*- mode: ruby -*-
# vi: set ft=ruby :

\$script = <<SCRIPT
update-alternatives --set editor /usr/bin/vim.basic --quiet
apt-get update && export DEBIAN_FRONTEND=noninteractive
for p in ppa:ondrej/php; do add-apt-repository -y $p; done && apt-get update
apt-get install -y nginx php$phpversion-cli php$phpversion-fpm php$phpversion-mysql php$phpversion-curl php$phpversion-dom php$phpversion-gd php$phpversion-mbstring php$phpversion-xml mysql-server-5.7 zip
apt-get -y dist-upgrade
mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf
sed -i 's/www-data/vagrant/g' /etc/nginx/nginx.conf
echo '[$name]
user = vagrant
group = vagrant
listen = /var/run/php$phpversion-fpm-$name.sock
listen.owner = vagrant
listen.group = vagrant
php_admin_value[disable_functions] = exec,passthru,shell_exec,system
php_admin_flag[allow_url_fopen] = off
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
chdir = /' > /etc/php/$phpversion/fpm/pool.d/$name.conf
echo 'server {
    listen 80;
    listen [::]:80;

    server_name $server_name;

    root /home/vagrant/www;
    index index.php index.html;

    location / {
        try_files \\\$uri \\\$uri/ =404;
    }
    location ~ \\\\.php$ {
        include snippets/fastcgi-php.conf;
        include fastcgi_params;
        fastcgi_pass unix:/run/php$phpversion-fpm-$name.sock;
        fastcgi_param SCRIPT_FILENAME \\\$document_root\\\$fastcgi_script_name;
    }
}' > /etc/nginx/sites-available/$server_name
sed -i 's/www-data/vagrant/g' /etc/php/$phpversion/fpm/pool.d/www.conf
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/$server_name /etc/nginx/sites-enabled/
systemctl restart nginx php$phpversion-fpm
sudo -u vagrant -i -- curl -s -o wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp && sudo mv wp /usr/local/bin/
sudo -u vagrant -i -- mkdir www && sudo -u vagrant -i -- chmod 755 www
sudo su - vagrant
echo -e "path: www
url: $server_name\n
core download:
  locale: pt_BR
  force: true\n
config create:
  dbname: $name
  dbuser: root
  extra-php: |
    define( 'WP_DEBUG', true );
    define( 'WP_MEMORY_LIMIT', '64M' );
  force: true\n
core install:
  title: $title
  admin_user: $admin_user
  admin_password: $admin_password
  admin_email: $admin_email
  force: true" > wp-cli.yml
sudo -u vagrant -i -- wp core download
sudo -u vagrant -i -- wp config create
sudo -u vagrant -i -- wp db create
sudo -u vagrant -i -- wp core install
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.network "forwarded_port", guest: 80, host: 80
  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.synced_folder "$current", "/home/vagrant/www"
  config.vm.synced_folder "$current/wp-content/themes/$name", "/home/vagrant/www/wp-content/themes/$name"
  config.vm.provision "shell", inline: \$script
end
DELIM

git add .
git commit -m "Init development" -q
