#!/bin/bash
#
# Shell script to set up Nginx serving the puppet demo HTML file on port 8080
# Chris Gilbert 03/08/2013
#

if ! dpkg -s puppetlabs-release >/dev/null 2>&1 || ! dpkg -s puppetlabs-common >/dev/null 2>&1; then
    echo Setting up puppetlabs repo.
    cd /tmp
    wget -nv http://apt.puppetlabs.com/puppetlabs-release-quantal.deb
    sudo dpkg -i puppetlabs-release-quantal.deb && rm puppetlabs-release-quantal.deb
    sudo apt-get -yq install puppet puppet-common
fi

if ! sudo puppet module list | grep -q jfryman-nginx; then
    echo Adding jfryman-nginx puppet module.
    sudo puppet module install jfryman/nginx
fi

#
# This is my allocated EC2 server, can't get public address from puppet facts
#
PUBLIC_DNS=ec2-54-213-110-30.us-west-2.compute.amazonaws.com
cat > /tmp/install_nginx.pp << EOF
    node default {
        class { 'nginx': }
           nginx::resource::vhost { "$PUBLIC_DNS":
                ensure          => present,
                listen_port     => 8080,
                www_root        => "/var/www/$PUBLIC_DNS",
          }
          
          file { "/var/www/":
                ensure          => directory,
                mode            => 644,
                recurse         => true,
                owner           => 'nginx'
          }
          
          file { "/var/www/$PUBLIC_DNS":
                ensure          => directory,
                mode            => 644,
                owner           => 'nginx',
                group           => 'nginx'
          }
        
          exec { 'wget_index':
              command           => "/usr/bin/wget https://raw.github.com/puppetlabs/exercise-webpage/master/index.html -O /var/www/$PUBLIC_DNS/index.html",
              creates           => "/var/www/$PUBLIC_DNS/index.html",
              require           => File["/var/www/$PUBLIC_DNS"]
          }
          
          file { "/var/www/$PUBLIC_DNS/index.html":
             owner              => 'nginx',
             group              => 'nginx',
             mode               => 644,
             require            => Exec['wget_index']
          }
    }
EOF

sudo puppet apply /tmp/install_nginx.pp

