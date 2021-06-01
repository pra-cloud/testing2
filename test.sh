#!/bin/bash

sudo apt-get update --assume-yes
#sudo apt install nginx --assume-yes
sudo apt upgrade
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt install mongodb --assume-yes
sudo apt install nodejs --assume-yes
node --version
npm --version
sudo apt-get install git --assume-yes
sudo npm install pm2 -g
sudo apt update && upgrade
sudo apt install apache2 --assume-yes
systemctl start apache2
systemctl enable apache2
apt-get install build-essential --assume-yes
sudo apt install jq -y
link=domainlink
git -C /var/www/html clone $link
mv /var/www/html/reponame/*/ /var/www/html/
#c=$(ls -l /var/www/html/testreactnode/ | grep "^d" | wc -l)
c=$(ls -l /var/www/html/ | grep "^d" | wc -l)
arr1=(/var/www/html/*/)
echo ${arr1[@]}
total=${#arr1[@]}
touch /etc/apache2/sites-available/reponame.conf
for(( i=0; i<$total; i++ ))
do
	type=`jq -r .deployment_type ${arr1[$i]}/deploy.json`
	if [ $type == react ]
	then
		portno=`jq -r .port_number ${arr1[$i]}/deploy.json`
		servname=`jq -r .server_name ${arr1[$i]}/deploy.json`
		servalias=`jq -r .server_alias ${arr1[$i]}/deploy.json`
		cd ${arr1[$i]}
		npm i
		npm run-script build
		pm2 serve build $portno --spa
		sudo tee -a  /etc/apache2/sites-available/reponame.conf >/dev/null << EOF
		<VirtualHost *:80>
		ServerName $servname 
		ServerAlias $servalias
    		ProxyRequests Off 
    		ProxyPreserveHost On 
    		ProxyVia Full 
    		<Proxy *>
      			Require all granted 
    		</Proxy>	 

    		<Location />
    		ProxyPass  http://127.0.0.1:$portno/
    		ProxyPassReverse http://127.0.0.1:$portno/
    		</Location>

    		<Directory "${arr1[$i]}"> 
    		AllowOverride All
    		</Directory>
		</VirtualHost>

		<VirtualHost *:443>
		ServerName $servname 
		ServerAlias $servalias
    		ProxyRequests Off 
    		ProxyPreserveHost On 
    		ProxyVia Full 
    		<Proxy *>
      			Require all granted 
    		</Proxy>	 

    		<Location />
    		ProxyPass  http://127.0.0.1:$portno/
    		ProxyPassReverse http://127.0.0.1:$portno/
    		</Location>

    		<Directory "${arr1[$i]}"> 
    		AllowOverride All
    		</Directory>
		</VirtualHost>
EOF
		cd
	elif [ $type == node ]
	then
		filename=`jq -r .file_name ${arr1[$i]}/deploy.json`
		nportno=`jq -r .port_number ${arr1[$i]}/deploy.json`
		servname=`jq -r .server_name ${arr1[$i]}/deploy.json`
		servalias=`jq -r .server_alias ${arr1[$i]}/deploy.json`
		cd ${arr1[$i]}
		npm i
		pm2 start $filename
		sudo tee -a  /etc/apache2/sites-available/reponame.conf >/dev/null << EOF
		<VirtualHost *:80>
		ServerName $servname 
		ServerAlias $servalias
    		ProxyRequests Off 
    		ProxyPreserveHost On 
    		ProxyVia Full 
    		<Proxy *>
      			Require all granted 
    		</Proxy>	 

    		<Location />
    		ProxyPass  http://127.0.0.1:$nportno/
    		ProxyPassReverse http://127.0.0.1:$nportno/
    		</Location>

    		<Directory "${arr1[$i]}"> 
    		AllowOverride All
    		</Directory>
		</VirtualHost>

		<VirtualHost *:443>
		ServerName $servname 
		ServerAlias $servalias
    		ProxyRequests Off 
    		ProxyPreserveHost On 
    		ProxyVia Full 
    		<Proxy *>
      			Require all granted 
    		</Proxy>	 

    		<Location />
    		ProxyPass  http://127.0.0.1:$nportno/
    		ProxyPassReverse http://127.0.0.1:$nportno/
    		</Location>

    		<Directory "${arr1[$i]}"> 
    		AllowOverride All
    		</Directory>
		</VirtualHost>
EOF
		cd
	elif [ $type == html ]
	then
		servname=`jq -r .server_name ${arr1[$i]}/deploy.json`
		servalias=`jq -r .server_alias ${arr1[$i]}/deploy.json`
		sudo tee -a  /etc/apache2/sites-available/reponame.conf >/dev/null << EOF
		<VirtualHost *:80>
		# This is the name of the vhost.
		ServerName $servname
		# These are alternative names for this same vhost.
        # We put the other domains here. They will all go to the same place.
		ServerAlias $servalias
		# Directory where the website code lives.
		DocumentRoot ${arr1[$i]}
		ErrorLog ${APACHE_LOG_DIR}/error.log
		CustomLog ${APACHE_LOG_DIR}/access.log combined
		<Directory />
			Options FollowSymLinks
			AllowOverride All
		</Directory>
		</VirtualHost>


		<VirtualHost *:443>
		# This is the name of the vhost.
        ServerName $servname
        # These are alternative names for this same vhost.
        # We put the other domains here. They will all go to the same place.
        ServerAlias $servalias
        # Directory where the website code lives.
        DocumentRoot ${arr1[$i]}
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        <Directory />
                Options FollowSymLinks
                AllowOverride All
        </Directory>
        </VirtualHost>
EOF
	else
		echo "Not an app"
	fi
done

##uncomment to check for changing the directory
#a2ensite reponame.conf
#systemctl restart apache2

##to install the code deploy agent in here
sudo apt install ruby-full -y
sudo apt install wget -y
cd /home/ubuntu/
wget https://aws-codedeploy-us-east-2.s3.us-east-2.amazonaws.com/latest/install
chmod +x ./install
#./install auto
sudo ./install auto > /tmp/logfile
sudo service codedeploy-agent status



