# Set global variables
#
# These variables can be changed based on the environment you are
# deploying to.
#
http = find_only_one(:http)
pe_http_host_path = "http://neptune.puppetlabs.lan/2.8/ci-ready"
pe_cluster_http_host_path = "http://#{http}"
pe_tarball = "puppet-enterprise-2.8.4-20-ga224f43-el-6-x86_64.tar"
#pe_tarball = "puppet-enterprise-2.8.4-16-g4af4d5a-el-6-x86_64.tar.gz"
pe_cluster_tarball = "pe_cluster.tar"

# install curl, ntpdate on all servers
hosts.each { |server|
  server.install_package("ntpdate")
  server.install_package("curl")
}

#######
#
# Values below this line should only need to be changed if the
# Scale Guide instructions themselves have been changed.
#
# If you identify an implementation specific value below, please
# parameterize it into the global variables section above.
#
#######

# Open defined ports on all servers
# FIXME: Currently beaker hangs while executing the iptables commands below
#        They are commented out to prevent execution while providing a
#        reference.
# {{{
#hosts.each { |server|
#  step "Server #{server}: Open ports 22, 443, 3306, 8140, 61613, 61616"
#  ports = ["22", "443", "3306", "8140", "61613", "61616"]
#  # drop all access and re-establish SSH
#  on server, "iptables -P INPUT DROP; iptables -P FORWARD DROP; iptables -P OUTPUT DROP; iptables -A INPUT -i eth0 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT; iptables -A OUTPUT -o eth0 -p tcp --sport 22  -m state --state ESTABLISHED -j ACCEPT"
#  on server, "service iptables restart"
#  # add ports
#  ports.each do |port|
#    on server, "iptables -A INPUT -i eth0 -p tcp --dport #{port} -m state --state NEW,ESTABLISHED -j ACCEPT"
#    on server, "iptables -A OUTPUT -o eth0 -p tcp --sport #{port} -m state --state ESTABLISHED -j ACCEPT"
#  end
#  on server, "service iptables restart"
#}
# }}}

# Set up HTTP server for installer and pe_cluster
# {{{

step "HTTP #{http}: Install ruby 1.9"
on http, "yum -y erase ruby*"
on http, "rpm -Uvh http://rbel.co/rbel6"
on http, "yum -y install ruby19"
on http, "ln -s /usr/bin/ruby19 /usr/bin/ruby"
on http, "ln -s /usr/bin/gem19 /usr/bin/gem"

step "HTTP #{http}: Create pe_cluster.tar"
http.install_package("git")
on http, "git clone https://github.com/eshamow/pe_scaling.git"
on http, "cd pe_scaling; git checkout 2.8_revised"
# get necessary hostnames and IP addresses
gateway = find_only_one(:deploy_gateway)
lb = find_only_one(:load_balancer)
data = find_only_one(:database)
active = find_only_one(:active_console)
active_ip = get_ip(find_only_one(:active_console))
passive = find_only_one(:passive_console)
passive_ip = get_ip(find_only_one(:passive_console))
primary = find_only_one(:primary_server)
primary_ip = get_ip(find_only_one(:primary_server))
servers = Hash.new
server_str = ""
hosts_as(:server).each { |server|
  server_str << "  - [#{server}, #{get_ip(server)}]\n"
}
# create settings.yaml
settings =<<EOF
---
  puppet_service_dns_name: #{lb}
  dg_hostname: #{gateway}
  dg_console_user: admin@example.com
  dg_console_pw: Puppet11
  dg_console_auth_db_password: dgconsoleauthpw
  dg_console_db_password: dgconsoledbuserpw
  balancer_name: #{lb}
  mysql_host: #{data}
  mysql_root_password: dgrootuserpw
  active_console_name: #{active}
  active_console_address: #{active_ip}
  console_user: admin@example.com
  console_pw: Puppet11
  console_auth_db_password: consoleuserpw
  console_db_password: consoledbuserpw
  passive_console_name: #{passive}
  passive_console_address: #{passive_ip}
  primary_master_name: #{primary}
  primary_master_address: #{primary_ip}
  masters:
#{server_str}
  smtp_server: localhost
  use_seeded_modules: false
EOF

create_remote_file(http, '/root/pe_scaling/2.8/settings.yaml', settings)
# run createfiles
on http, "cd /root/pe_scaling/2.8; ./createfiles.rb; tar cf /root/pe_cluster.tar pe_cluster"
# run HTTP server
# FIXME: iptables issue needs to be resolved. See comment above
#on http, "iptables -A INPUT -i eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT"
#on http, "iptables -A OUTPUT -o eth0 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT"
daemon =<<EOF
require 'webrick'

root = File.expand_path '/root'
server = WEBrick::HTTPServer.new :Port => 80, :DocumentRoot => root

WEBrick::Daemon.start
server.start
EOF
create_remote_file(http, '/root/daemon.rb', daemon)
on http, "ruby /root/daemon.rb"
# }}}

# Set up Deployment Gateway
# {{{
gateway = find_only_one(:deploy_gateway)

step "Gateway #{gateway}: Install PE"
on gateway, "cd /root; curl -O #{pe_http_host_path}/#{pe_tarball}"
on gateway, "cd /root; curl -O #{pe_cluster_http_host_path}/#{pe_cluster_tarball}"
on gateway, "cd /root; tar -xf pe_cluster.tar"
on gateway, "cd /root; tar -xf puppet-enterprise*.tar"
on gateway, "cd puppet-enterprise*; ./puppet-enterprise-installer -a ../pe_cluster/answers/scaling_#{gateway}.answers"

step "Gateway #{gateway}: Perform step0"
on gateway, "cd /root/pe_cluster; ./step0.sh"
# }}}

# Set Up the Load Balancer
# {{{
lb = find_only_one(:load_balancer)

step "Load Balancer #{lb}: Install PE"
on lb, "cd /root; curl -O #{pe_http_host_path}/#{pe_tarball}"
on lb, "cd /root; curl -O #{pe_cluster_http_host_path}/#{pe_cluster_tarball}"
on lb, "cd /root; tar -xf pe_cluster.tar"
on lb, "cd /root; tar -xf puppet-enterprise*.tar"
on lb, "cd puppet-enterprise*; ./puppet-enterprise-installer -a ../pe_cluster/answers/scaling_#{lb}.answers"

step "Gateway #{gateway}: Sign Load Balancer #{lb} cert"
on gateway, "puppet cert sign #{lb}"

step "Load Balancer #{lb}: Run puppet"
on lb, puppet_agent('-t'), :acceptable_exit_codes => [0,2]

step "Gateway #{gateway}: Perform step1"
on gateway, "cd /root/pe_cluster; ./step1.sh"

step "Load Balancer #{lb}: Run puppet"
on lb, puppet_agent('-t'), :acceptable_exit_codes => [0,2]
# }}}

# Set Up MySQL Database
# {{{
step "MySQL #{database}: Install PE"
on database, "cd /root; curl -O #{pe_http_host_path}/#{pe_tarball}"
on database, "cd /root; curl -O #{pe_cluster_http_host_path}/#{pe_cluster_tarball}"
on database, "cd /root; tar -xf pe_cluster.tar"
on database, "cd /root; tar -xf puppet-enterprise*.tar"
on database, "cd puppet-enterprise*; ./puppet-enterprise-installer -a ../pe_cluster/answers/scaling_#{database}.answers"

step "Database: Run puppet"
on database, puppet_agent('-t'), :acceptable_exit_codes => [0,1,2]

step "Gateway #{gateway}: Sign Database #{database} cert"
on gateway, "puppet cert sign #{database}"

step "Database: Run puppet"
on database, puppet_agent('-t'), :acceptable_exit_codes => [0,2]

step "Gateway #{gateway}: Perform step2"
on gateway, "cd /root/pe_cluster; ./step2.sh"

step "Database: Run puppet"
on database, puppet_agent('-t'), :acceptable_exit_codes => [0,2]

# }}}

# Set Up Active/Passive Console/CA
# {{{
agents.each { |dash|
  if dash['roles'].include?('passive_console') or dash['roles'].include?('active_console')
    step "Console #{dash}: Install MySQL client"
    dash.install_package("mysql")

    step "Console #{dash}: Install PE"
    on dash, "cd /root; curl -O #{pe_http_host_path}/#{pe_tarball}"
    on dash, "cd /root; curl -O #{pe_cluster_http_host_path}/#{pe_cluster_tarball}"
    on dash, "cd /root; tar -xf pe_cluster.tar"
    on dash, "cd /root; tar -xf puppet-enterprise*.tar"
    on dash, "cd puppet-enterprise*; ./puppet-enterprise-installer -a ../pe_cluster/answers/scaling_#{dash}.answers"
  end
}
active = find_only_one(:active_console)
passive = find_only_one(:passive_console)

step "Gateway #{gateway}: Copy shared CA module"
scp_from( gateway, "/root/pe_shared_ca", "/tmp/")
scp_to( active, "/tmp/pe_shared_ca", "/root/")
scp_to( passive, "/tmp/pe_shared_ca", "/root/")

step "Active Console #{active}: Run ./active.sh"
on active, "cd /root/pe_cluster; ./active.sh"

step "Passive Console #{passive}: Run ./passive.sh"
on passive, "cd /root/pe_cluster; ./passive.sh"

step "Gateway #{gateway}: Perform step3"
on gateway, "cd /root/pe_cluster; ./step3.sh"

agents.each { |dash|
  if dash['roles'].include?('passive_console') or dash['roles'].include?('active_console')
    step "Console #{dash}: Run puppet"
    on dash, puppet_agent('-t'), :acceptable_exit_codes => [0,2]
  end
}
# }}}

# Setting Up the Primary Server, Secondary Server, and any additional master servers
# {{{

primary = find_only_one(:primary_server)

step "Primary Master #{primary}: Install PE"
on primary, "cd /root; curl -O #{pe_http_host_path}/#{pe_tarball}"
on primary, "cd /root; curl -O #{pe_cluster_http_host_path}/#{pe_cluster_tarball}"
on primary, "cd /root; tar -xf pe_cluster.tar"
on primary, "cd /root; tar -xf puppet-enterprise*.tar"
on primary, "cd puppet-enterprise*; ./puppet-enterprise-installer -a ../pe_cluster/answers/scaling_#{primary}.answers"

hosts_as(:server).each { |server|
  step "Master #{server}: Install PE"
  on server, "cd /root; curl -O #{pe_http_host_path}/#{pe_tarball}"
  on server, "cd /root; curl -O #{pe_cluster_http_host_path}/#{pe_cluster_tarball}"
  on server, "cd /root; tar -xf pe_cluster.tar"
  on server, "cd /root; tar -xf puppet-enterprise*.tar"
  on server, "cd puppet-enterprise*; ./puppet-enterprise-installer -a ../pe_cluster/answers/scaling_#{server}.answers"

}

# assume that modules are installed on primary
# rsync from primary to servers
hosts_as(:server).each { |server|
  on server, "echo '* * * * * rsync -a -e ssh root@#{primary}:/etc/puppetlabs/puppet/modules /etc/puppetlabs/puppet/modules' >> /var/spool/cron/root"
}

superserverarray = hosts_as(:server)
superserverarray << primary

superserverarray.each { |server|
  step "Gateway #{gateway}: Copy shared CA module"
  scp_from( gateway, "/root/pe_shared_ca", "/tmp/")
  scp_to( server, "/tmp/pe_shared_ca", "/root/")

  step "Server #{server}: Run ./master.sh"
  on server, "cd /root/pe_cluster; ./master.sh"

  step "Gateway #{gateway}: Sign Master #{server} cert"
  on gateway, "puppet cert sign #{server} --allow-dns-alt-names"

  step "Server #{server}: Run puppet"
  on server, puppet_agent('-t'), :acceptable_exit_codes => [0,2]
}

step "Gateway #{gateway}: Perform step4"
on gateway, "cd /root/pe_cluster; ./step4.sh"

superserverarray.each { |server|
  step "Server #{server}: Run puppet"
  on server, puppet_agent('-t'), :acceptable_exit_codes => [0,2]
}
# }}}

# Setting Up an agent
# {{{
hosts_as(:agent_only).each { |server|
  step "Agent #{server}: Install PE and stop puppet"
  answers =<<EOF
q_all_in_one_install=n
q_database_install=n
q_fail_on_unsuccessful_master_lookup=y
q_install=y
q_puppet_cloud_install=n
q_puppet_enterpriseconsole_install=n
q_puppetagent_certname=#{server}
q_puppetagent_install=y
q_puppetagent_server=#{lb}
q_puppetca_install=n
q_puppetdb_install=n
q_puppetmaster_install=n
q_run_updtvpkg=n
q_vendor_packages_install=y
q_puppet_symlinks_install=y
EOF
  create_remote_file(server, '/tmp/answers', answers)
  on server, "cd /root; curl -O #{pe_http_host_path}/#{pe_tarball}"
  on server, "cd /root; tar -xf puppet-enterprise*.tar"
  on server, "cd puppet-enterprise*; ./puppet-enterprise-installer -a /tmp/answers && /etc/init.d/pe-puppet stop"

  step "Agent #{server}: Run puppet"
  on server, puppet_agent('-t'), :acceptable_exit_codes => [0,1,2]

  step "Active CA #{active}: Sign Agent #{server} cert"
  on active, "puppet cert sign #{server}"
  on active, "/opt/puppet/bin/rake -sf /opt/puppet/share/puppet-dashboard/Rakefile defaultgroup:ensure_default_group RAILS_ENV=production"

  step "Agent #{server}: Run puppet"
  on server, puppet_agent('-t'), :acceptable_exit_codes => [0,2]
}
# }}}
