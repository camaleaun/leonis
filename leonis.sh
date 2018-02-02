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

server_name="$name.local"
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

phpversion="7.1"
read -p "php version: ($phpversion) " phpversion_read;
if [ -n "$phpversion_read" ]; then
  phpversion=$phpversion_read;
fi

theme_uri="https://fervidum.github.io/salvia/"
read -p "theme uri: ($theme_uri) " theme_uri_read;
if [ -n "$theme_uri_read" ]; then
  theme_uri=$theme_uri_read;
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

#"/home/camaleaun/vagrant/"
vagrant_folder="."
read -p "vagrant folder: ($vagrant_folder/) " vagrant_folder_read;
if [ -n "$vagrant_folder_read" ]; then
  vagrant_folder=$vagrant_folder_read;
fi

#user_email="camaleaun@gmail.com"
#user_name="Gilberto Tavares"

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

rm -f style.css
cat <<EOT >> style.css
/*
Theme Name: $title
Theme URI: $theme_uri
Author: $author
Author URI: $author_uri
Version: 1.0.0
Text Domain: $name
*/

EOT

rm -f index.php
cat <<EOT >> index.php
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

rm -f header.php
cat <<EOT >> header.php
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

rm -f footer.php
cat <<EOT >> footer.php
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
.vagrant
*.log
EOT

rm -f .editorconfig
cat <<EOT >> .editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = tab
indent_size = 4

[{*.css,*.js}]
indent_style = space
indent_size = 2

[Gruntfile.js]
indent_style = tab
indent_size = 4

[{*.json,*.yml,.jshintrc}]
indent_style = space
indent_size = 4
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

#echo "cat > $vagrant_folder/Vagrantfile"

cat > $vagrant_folder/Vagrantfile <<DELIM
# -*- mode: ruby -*-
# vi: set ft=ruby :

#export DEBIAN_FRONTEND=noninteractive

\$script = <<SCRIPT
update-alternatives --set editor /usr/bin/vim.tiny --quiet
add-apt-repository -y ppa:nginx/development
add-apt-repository -y ppa:ondrej/php
apt-get update
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get install -y nginx php$phpversion-curl php$phpversion-dom php$phpversion-gd php$phpversion-fpm php$phpversion-mysql php$phpversion-cli mysql-server-5.7
cat <<EOT >> sendmail.sh
#! /bin/bash
EOT
chmod +x sendmail.sh
mv sendmail.sh /usr/sbin/sendmail
echo '[$name]
user = vagrant
group = vagrant
listen = /var/run/php$phpversion-fpm-$name.sock
listen.owner = www-data
listen.group = www-data
php_admin_value[disable_functions] = exec,passthru,shell_exec,system
php_admin_flag[allow_url_fopen] = off
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
chdir = /' > /etc/php/$phpversion/fpm/pool.d/$name.conf
service php$phpversion-fpm restart
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
}' > /etc/nginx/sites-available/$name
chmod 644 /etc/nginx/sites-available/$name
ln -s /etc/nginx/sites-available/$name /etc/nginx/sites-enabled/$name
rm /etc/nginx/sites-enabled/default
rm -Rf /var/www
service nginx restart
curl -O -s https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
cat <<EOT >> wp-cli.yml
path: www
url: http://$server_name\n
core download:
    locale: pt_BR\n
config create:
    dbname: $name
    dbuser: root
    dbpass: root
    extra-php: |
        define( 'WP_DEBUG', true );\n
core install:
    title: $title
    admin_user: $admin_user
    admin_password: $admin_password
    admin_email: $admin_email
EOT
chown vagrant:vagrant wp-cli.yml
sudo -u vagrant -i -- wp core download
sudo -u vagrant -i -- wp config create
sudo -u vagrant -i -- wp db create
sudo -u vagrant -i -- wp core install
sudo -u vagrant -i -- wp theme activate $name
sudo -u vagrant -i -- wp plugin delete \$(sudo -u vagrant -i -- wp plugin list --status=inactive --field=name)
sudo -u vagrant -i -- wp theme delete \$(sudo -u vagrant -i -- wp theme list --status=inactive --field=name)
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.synced_folder "$current", "/home/vagrant/www/wp-content/themes/$name"
  config.vm.provision "shell", inline: \$script
end
DELIM

git add .
git commit -m "Init development" -q
