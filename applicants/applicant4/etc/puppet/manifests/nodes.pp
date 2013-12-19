node default {
	include nginx
	#include hosts
	#include ntp
	#include httpd
	#include ntpdate
}

node 'blankpc.mingah.com' inherits default {}
# node 'blankpc1.mingah.com' inherits default {}
