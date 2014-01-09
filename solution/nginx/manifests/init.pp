class nginx {
  File {
    owner => 'root',
    group => 'root',
  }

  yumrepo { 'nginx repo':
    baseurl => 'http://nginx.org/packages/centos/$releasever/$basearch/',
  }

  package { 'nginx':
    ensure  => installed,
    require => Yumrepo['nginx repo'],
  }

  file { '/etc/nginx/nginx.conf':
    ensure  => file,
    source  => 'puppet:///modules/nginx/nginx.conf',
    require => Package['nginx'],
  }

  file { '/etc/nginx/conf.d/default.conf':
    ensure  => file,
    source  => 'puppet:///modules/nginx/default.conf',
    require => Package['nginx'],
  }

  file { ['/etc/nginx/html',
          '/etc/nginx/logs']:
    ensure => directory,
    require => Package['nginx'],
  }

  file { '/etc/nginx/html/index.html':
    ensure  => file,
    source  => 'puppet:///modules/nginx/index.html',
    require => Package['nginx'],
  }

  service { 'nginx':
    ensure    => running,
    enable    => true,
    subscribe => [File['/etc/nginx/nginx.conf'],
                  File['/etc/nginx/conf.d/default.conf'],
                  File['/etc/nginx/html/index.html']],
  }
}
