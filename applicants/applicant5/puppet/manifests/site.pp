#/etc/puppet/mainfests/site.pp

#install enginex and configure it
node default {
	include nginx
	}
import "classes/*"
