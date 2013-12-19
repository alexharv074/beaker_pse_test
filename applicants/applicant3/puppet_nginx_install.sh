#!/bin/bash
# Author: Garry Harthill
# Date: 2013/8/4
# 
# Script for installing nginx to listen on port 8080 and serve content located on github
# This script ensures Puppet is installed using Yum and the puppetlabs yum repo. It then 
# uses Puppet to perform the nginx installation and configuration.
#
# 
# Notes:
# This script inlines the yum repo and the Puppet manifest to make it easier to distribute
# and use.
#
# nginx is found in epel yum repo
#
# Running displays warning about Hiera config. Could add a line to touch this file location
# and the warning goes away. Doesn't effect functonality though
#
##############################################################################################
# Checks for existence of official puppet yum repo. If not there is installs it by creating
# the repo file in /etc/yum.repo.d
##############################################################################################
check_puppet_repo() {
	echo -n "Checking for Puppetlabs yum repo..."
	if [ $(yum repolist| grep puppetlabs| wc -l) -ge 1 ]; then
		echo "Already installed"
	else
		echo -n "Installing..."
		cat > /etc/yum.repos.d/puppet.repo << "EOF"
[puppetlabs]
name=Puppet Labs Packages
baseurl=http://yum.puppetlabs.com/el/$releasever/products/$basearch/
enabled=1
gpgcheck=1
gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs

[puppetlabs-deps]
name=Puppet Labs Dependencies EL 6 - x86_64
baseurl=http://yum.puppetlabs.com/el/6/dependencies/x86_64
enabled=1
gpgcheck=1
gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
keepalive=1
EOF
		echo "Installed"
	fi
}
##############################################################################################
# nginx can't be found in default Centos repos so needed to make sure epel was added to the
# system. 
##############################################################################################
check_epel_repo() {
	echo -n "Checking for EPEL yum repo..."
	if [ $(yum repolist| grep epel| wc -l) -ge 1 ]; then
		echo "Already installed"
	else
		echo -n "Installing..."
		rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
		if [ $(echo $?) -eq 0 ]; then
			echo "EPEL repo installed"
		fi
	fi
}
##############################################################################################
# Installs puppet and vcsrepo and iptables puppetforge modules
##############################################################################################
install_puppet() {
	echo -n "Checking for Puppet..."
	if [ $(rpm -qa| grep puppet| wc -l) -eq 1 ]; then
		echo "Already installed"
	else
		echo "Installing puppet"
		yum -y install puppet
	fi
	echo "Checking for vcsrepo module..."
	if [ $(puppet module list| grep "puppetlabs-vcsrepo"| wc -l) -eq 1 ]; then
		echo "   VCS module already installed"
	else
		puppet module install puppetlabs/vcsrepo
		if [ $(echo $?) -eq 0 ]; then
			echo "   VCS module Installed"
		fi
	fi
	echo "Checking for iptables module..."
	if [ $(puppet module list| grep "arusso-iptables"| wc -l) -eq 1 ]; then
		echo "   iptables module already installed"
	else
		puppet module install arusso/iptables
		if [ $(echo $?) -eq 0 ]; then
			echo "   iptables module Installed"
		fi
	fi
	
}
##############################################################################################
# Inlines puppet manifest which installs nginx and git. Configures nginx and clones the git
# repo from github.
##############################################################################################
run_nginx_manifest() {
	echo "Running nginx puppet manifest..."
	puppet apply << "EOF"
	
package {"nginx":
	ensure	=> "installed",
}
package {"git":
	ensure 	=> "installed",
}

file { "/etc/nginx/conf.d/default.conf":
	require	=> Package[ "nginx" ],
	path 	=> "/etc/nginx/conf.d/default.conf",
	content => inline_template("
server {
    listen       8080;

    location / {
        root   /opt/code;
        index  index.html;
    }
}"),
}

service { "nginx":
	ensure 		=> running,
	require 	=> [ Vcsrepo["/opt/code"], Package["nginx"] ],
	subscribe 	=> File["/etc/nginx/conf.d/default.conf"],
}

vcsrepo { "/opt/code":
	ensure 		=> present,
	provider 	=> git,
	require 	=> [ Package["git"] ],
	source 		=> "https://github.com/puppetlabs/exercise-webpage.git",
	revision	=> 'master',
}
EOF
}
##############################################################################################
# Inlines puppet manifest which configures the iptables firewall for nginx running on 8080
# Also allows port 22 access for ssh
##############################################################################################
run_iptables_manifest() {
	echo  "Running firewall puppet manifest..."

	puppet apply << "EOF"

service { "iptables":
	ensure 		=> running,
	subscribe 	=> File[ "/etc/sysconfig/iptables" ],
}

iptables::rule { 'forward-allow-related-established':
 	comment			=> 'Related, Established',
 	order			=> '1',
 	action			=> 'ACCEPT',
 	state			=> 'RELATED,ESTABLISHED',
 	chain			=> 'INPUT',
}

iptables::rule { 'allow-inbound-8080':
  comment          => 'Allow tcp 8080 to nginx webserver',
  order            => '10',
  destination_port => '8080',
  protocol         => 'tcp',
  action           => 'ACCEPT',
  chain            => 'INPUT',
}

iptables::rule { 'allow-inbound-22':
  comment          => 'Allow tcp 22 for ssh access to server',
  order            => '5',
  destination_port => '22',
  protocol         => 'tcp',
  action           => 'ACCEPT',
  chain            => 'INPUT',
}

iptables::rule { 'input-drop-all':
  comment          => 'Drop everything else',
  order            => '999',
  action           => 'REJECT',
  chain            => 'INPUT',
}

iptables::rule { 'forward-drop-all':
  comment          => 'Drop everything else',
  order            => '999',
  action           => 'REJECT',
  chain            => 'FORWARD',
}
EOF
}

##############################################################################################
# Main - runs some checks to make sure Redhat and that it's run as root then it performs the
# installation and configuration.
##############################################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $EUID != "0" ]; then
   echo "This script must be run as root"
   exit 1
fi

if [ ! -f /etc/redhat-release ]; then
	echo "This is not a Redhat distro...Exiting"
	exit 1
else
	echo -n "Redhat compatible distro found: " && cat /etc/redhat-release

	check_puppet_repo
	check_epel_repo
	install_puppet
	run_nginx_manifest
	run_iptables_manifest

fi
