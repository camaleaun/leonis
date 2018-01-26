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

server_name=$name.local
admin_user=$name
admin_password=$name
admin_email=$name@$server_name

phpversion="7.0"

title=${name^}
theme_uri="https://fervidum.github.io/salvia/"
author="Envolve"
author_uri="http://www.envolvelabs.com.br/"

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

[*.json,.jshintrc]
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

cat > ./Vagrantfile <<DELIM
# -*- mode: ruby -*-
# vi: set ft=ruby :

\$script = <<SCRIPT
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get update
apt-get install -y nginx php$phpversion-curl php$phpversion-fpm php$phpversion-mysql php$phpversion-cli mysql-server
sudo update-alternatives --set editor /usr/bin/vim.basic --quiet
cat <<EOT >> sendmail.sh
#! /bin/bash
EOT
chmod +x sendmail.sh
mv sendmail.sh /usr/sbin/sendmail
echo 'server {
    listen 80;
    listen [::]:80;

    server_name salvia.local;

    root /var/www;
    index index.php index.html;

    location / {
        try_files \\\$uri \\\$uri/ =404;
    }
    location ~ \\\\.php$ {
        include snippets/fastcgi-php.conf;
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www\\\$fastcgi_script_name;
    }
}' > /etc/nginx/sites-available/$name
chmod 644 /etc/nginx/sites-available/$name
ln -s /etc/nginx/sites-available/$name /etc/nginx/sites-enabled/$name
rm -Rf /var/www/html
chown -R vagrant:vagrant /var/www
service nginx restart
curl -O -s https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
cat <<EOT >> wp-cli.yml
path: /var/www
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
  config.vm.synced_folder ".", "/var/www/wp-content/themes/$name"
  config.vm.provision "shell", inline: \$script
end
DELIM

git add .
git commit -m "Init development" -q
