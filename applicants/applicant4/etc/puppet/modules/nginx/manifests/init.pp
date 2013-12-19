class nginx {
      $service_name = 'nginx'
      $conf_file    = 'nginx.conf'

      package { 'nginx':
        ensure => installed
      }

      service { 'nginx':
        name      => $service_name,
        ensure    => running,
        enable    => true,
        subscribe => File['nginx.conf']
      }

      file { 'nginx.conf':
        path    => '/etc/nginx/nginx.conf',
        ensure  => file,
        require => Package['nginx'],
        source   => "puppet:///modules/nginx/nginx.conf"
      }

	exec { "git clone https://github.com/puppetlabs/exercise-webpage":
	   cwd => "/usr/share/nginx",
           creates  =>  "/usr/share/nginx/exercise-webpage/index.html",
	   path => "/bin"
	}
}


