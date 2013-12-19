#/etc/puppet/manifests/classes/nginx.pp
class nginx {
	package { 'nginx':
    		ensure => installed,
	}
	file { '/usr/share/nginx/html/index.html':
		source => "puppet:///files/index.html",
		mode => 644,
 		owner => root,
		group => root,	
		ensure => present,
	}
	file { '/etc/nginx/conf.d/default.conf':
		source => "puppet:///files/default.conf",
		mode => 644,
 		owner => root,
		group => root,	
		ensure => present,
		require => Package['nginx'],
	}
	service { 'nginx':
		ensure => running,
		enable => true,
		require => File['/etc/nginx/conf.d/default.conf'],
		}
}
