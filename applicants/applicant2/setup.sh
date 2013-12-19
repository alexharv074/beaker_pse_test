#!/bin/bash
################################################################################
# $Id: setup.sh,v 1.3 2013/09/11 11:58:14 chlewis Exp chlewis $
################################################################################
## Overview
################################################################################
# This script will automate the installation of a nginx web server on 
# http://localhost:8080 with data populated using the data from 
# https://github.com/puppetlabs/exercise-webpage
# Assumptions
# The script assumes there is a default OS install (Ubuntu/Redhat) with no 
# additional packages selected and that it is connected to the internet
###############################################################################
## Useful links
###############################################################################
# http://puppetlabs.com/blog/deploying-puppet-in-client-server-standalone-and-\
# massively-scaled-environments
# http://docs.puppetlabs.com/guides/installation.html
# http://www.puppetcookbook.com/posts/install-package.html
###############################################################################
## Version History/Change log
###############################################################################
# 2013-09-11 cwl Tested against Ubuntu server 12.04 LTS 64 bit
# 2013-09-11 cwl Tested against RedHat server 6u4 64 bit 
# 2013-09-10 cwl Tested against Ubuntu desktop 12.04 LTS 64 bit
# 2013-09-10 cwl Created
###############################################################################
## Exit codes
###############################################################################
# 0 = successful
# 1 = not running as the root user
# 3 = unknown OS
###############################################################################
## Functions
###############################################################################
function v_log(){ # This function will print strings passed to it if
	if	[ $VERBOSE == 1 ]; then
		echo $1 $2 $3 $4 $5 $6 $7 $8 $9			
	fi
}
function usage() { # This function displays the usage information
  echo "Usage: ${SCRIPT_NAME}  {verbose}"
  echo "Usage: ${SCRIPT_NAME} -v "
  echo "Example: ${SCRIPT_NAME} : Run in normal mode to setup nginx webserver"
  echo "Example: ${SCRIPT_NAME} -v : Run in verbose mode to inform what script is doing"
}
###############################################################################
## Global Variable declarations
###############################################################################
SCRIPT_NAME=`basename $0` #Sets the variable to the name of the script
NGINX_WEB_CONF=/etc/puppet/modules/nginx/files/example-webpages
NGINX_INIT=/etc/puppet/modules/nginx/manifests/init.pp
NGINX_CONFIG=/etc/puppet/modules/nginx/manifests/config.pp
SITES=/etc/puppet/manifests/sites.pp
GIT_INIT=/etc/puppet/modules/git/manifests/init.pp
GIT_CONFIG=/etc/puppet/modules/git/manifests/config.pp
VERBOSE=0 # Set a default value for verbose
###############################################################################
## Main
###############################################################################
v_log "`date +%H:%M` Script starting"
# Check if we running as root if not error and exit
if [ "$(id -u)" != "0" ]
then
	echo "This script must be run as root"
	exit 1
fi
# Take command line args
while getopts ":v" opt;
do
  case $opt in
    v) VERBOSE=1 ;; # Print information to console
	\?) echo "Invalid option: -$OPTARG" 
	   usage
	   exit 1 ;;
	esac
done
# Check OS
if [ -f /etc/debian_version ]
then
    DISTRO="Debian"
    # or Ubuntu
elif [ -f /etc/redhat-release ]
then
    DISTRO="RedHat"
    # or CentOS or Fedora
elif [ -f /etc/lsb-release ]
then
    . /etc/lsb-release
    DISTRO=$DISTRIB_ID
else
    DISTRO=$(uname -s)
fi
v_log "`date +%H:%M` OS=${DISTRO}"
if [ ! -f /etc/puppet/puppet.conf ]
then
	if [ "$DISTRO" == "Debian" ] || [ "$DISTRO" == "Ubuntu" ]
	then
		# Install puppet
		v_log "`date +%H:%M` Installing Puppet"
		/usr/bin/apt-get install puppet -y > /dev/null 2>&1
		sed -i 's/START=no/START=yes/g' /etc/default/puppet
	elif [ "$DISTRO" == "RedHat" ]
	then
		v_log "`date +%H:%M` Installing Puppet"
		OS_VERSION=`lsb_release -rs | cut -f1 -d.`
		case $OS_VERSION in
		5) 	/bin/rpm -ivh http://yum.puppetlabs.com/el/5/products/i386/puppetlabs-release-5-7.noarch.rpm >/dev/null 2>&1;;
		6)	/bin/rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-7.noarch.rpm >/dev/null 2>&1;;
		*)	echo "Not sure how to run on this OS exiting"
			exit 3
			;;
		esac
		/usr/bin/yum-config-manager --enable rhel-6-server-optional-rpms
		/usr/bin/yum install puppet -y > /dev/null 2>&1
	fi
else
	v_log "`date +%H:%M` Skipping install of puppet as it already exists"
fi

# Set it to auto start
v_log "`date +%H:%M` Setting Puppet to auto start"
puppet resource service puppet ensure=running enable=true

# Now puppet is running set nginx to install using a module
mkdir -p /etc/puppet/modules/nginx/manifests /etc/puppet/modules/nginx/files /etc/puppet/manifests
if [ ! -f $NGINX_WEB_CONF ]
then
	v_log "`date +%H:%M` Creating $NGINX_WEB_CONF"
	tee $NGINX_WEB_CONF << 'NGINX_WEB_CONF_EOF'
	server {
		listen   8080;
		root /var/www/exercise-webpage;
		index index.html index.htm;
		server_name localhost;
		location / {
			try_files $uri $uri/ /index.html;
		}
		location /doc/ {
			alias /usr/share/doc/;
			autoindex on;
			allow 127.0.0.1;
			deny all;
		}
	}	
NGINX_WEB_CONF_EOF
else
	v_log "`date +%H:%M` Skipping $NGINX_WEB_CONF as it already exists"
fi
if [ ! -f $NGINX_INIT ]
then
	v_log "`date +%H:%M` Creating $NGINX_INIT"
	tee $NGINX_INIT << 'NGINX_INIT_EOF'
	class nginx {
		include nginx::config
	}	
NGINX_INIT_EOF
else
	v_log "`date +%H:%M` Skipping $NGINX_INIT as it already exists"
fi
if [ ! -f $NGINX_CONFIG ]
then
	v_log "`date +%H:%M` Creating $NGINX_CONFIG"
	tee $NGINX_CONFIG << 'NGINX_CONFIG_EOF'
	class nginx::config {
		package { "nginx":
			ensure => present,
		}
		service { "nginx":
			require => Package["nginx"],
			ensure => running,
			enable => true,
			subscribe  => File['/etc/nginx/sites-available/example-webpages'],
		}
		file { '/etc/nginx/sites-available/example-webpages':
			require => Package["nginx"],
			ensure => file,
			mode   => 660,
			source => '/etc/puppet/modules/nginx/files/example-webpages',
		}
		file { '/etc/nginx/sites-enabled/example-webpages':
			require => Package["nginx"],
			ensure => 'link',
			target => '/etc/nginx/sites-available/example-webpages',
		}
		file { "/etc/nginx/sites-enabled":
			require => Package["nginx"],
			ensure  => 'directory',
			recurse => true,
			purge   => true,
		}
		file { "/etc/nginx/sites-available":
			require => Package["nginx"],
			ensure  => 'directory',
			recurse => true,
			purge   => true,
		}
	}
NGINX_CONFIG_EOF
else
	v_log "`date +%H:%M` Skipping $NGINX_CONFIG as it already exists"
fi
# Add the module to run under node.pp
if [ ! -f $SITES ]
then
	v_log "`date +%H:%M` Creating $SITES"
	tee $SITES << 'SITES_EOF'
	node default {
			include git
			include nginx
	}
SITES_EOF
else
	v_log "`date +%H:%M` Skipping $SITES as it already exists"
fi
# Now the webserver is setup install git
mkdir -p /etc/puppet/modules/git/manifests
if [ ! -f $GIT_INIT ]
then
	v_log "`date +%H:%M` Creating $GIT_INIT"
	tee $GIT_INIT << 'GIT_INIT_EOF'
	class git {
		include git::config
	}	
GIT_INIT_EOF
else
	v_log "`date +%H:%M` Skipping $GIT_INIT as it already exists"
fi
if [ ! -f $GIT_CONFIG ]
then
	v_log "`date +%H:%M` Creating $GIT_CONFIG"
	tee $GIT_CONFIG << 'GIT_CONFIG_EOF'
	class git::config {
		require nginx
		package { "git":
			ensure => present,
		}
		$www_dirs = [ "/var/www", "/var/www/exercise-webpage"]
		file { $www_dirs:
			ensure => "directory",
			owner  => "www-data",
			mode   => 755,
		}
		exec { "download_website":
			command => "git clone https://github.com/puppetlabs/exercise-webpage /var/www/exercise-webpage",
			path => "/usr/bin",
			unless => "test -f /var/www/exercise-webpage/index.html",
			notify => Service[nginx],
			require => Package["git"],
		}
	}
GIT_CONFIG_EOF
else
	v_log "`date +%H:%M` Skipping $GIT_CONFIG as it already exists"
fi
v_log "Running puppet to apply configuration"
# Make puppet apply the config to the server
puppet apply /etc/puppet/manifests/sites.pp
v_log "`date +%H:%M` Script completed"
###############################################################################
## End
###############################################################################
