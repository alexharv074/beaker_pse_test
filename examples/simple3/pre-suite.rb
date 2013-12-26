test_name 'Install Puppet Enterprise' do
  host_os_tarball_dir = '/var/tmp'
  pe_tarball_file = 'puppet-enterprise-3.1.0-el-6-x86_64.tar.gz'
  pe_tarball_dir = pe_tarball_file.sub('.tar.gz', '')
  answers = <<EOF
q_all_in_one_install=y
q_backup_and_purge_old_configuration=n
q_backup_and_purge_old_database_directory=n
q_database_host=localhost
q_database_install=y
q_database_port=5432
q_database_root_password=qrOZrLBSkDXf8hjQZgZW
q_database_root_user=pe-postgres
q_install=y
q_pe_database=y
q_puppet_cloud_install=n
q_puppet_enterpriseconsole_auth_database_name=console_auth
q_puppet_enterpriseconsole_auth_database_password=gTQ7P54PMTnZc8cS72AL
q_puppet_enterpriseconsole_auth_database_user=console_auth
q_puppet_enterpriseconsole_auth_password=puppetlabs
q_puppet_enterpriseconsole_auth_user_email=admin@example.com
q_puppet_enterpriseconsole_database_name=console
q_puppet_enterpriseconsole_database_password=1zpTwNCwSyRcQN7BiLzC
q_puppet_enterpriseconsole_database_user=console
q_puppet_enterpriseconsole_httpd_port=443
q_puppet_enterpriseconsole_install=y
q_puppet_enterpriseconsole_master_hostname=localhost
q_puppet_enterpriseconsole_smtp_host=localhost
q_puppet_enterpriseconsole_smtp_password=
q_puppet_enterpriseconsole_smtp_port=25
q_puppet_enterpriseconsole_smtp_use_tls=n
q_puppet_enterpriseconsole_smtp_user_auth=n
q_puppet_enterpriseconsole_smtp_username=
q_puppet_symlinks_install=y
q_puppetagent_certname=localhost
q_puppetagent_install=y
q_puppetagent_server=localhost
q_puppetdb_database_name=pe-puppetdb
q_puppetdb_database_password=2fChtVIUCYdlMJCDLssy
q_puppetdb_database_user=pe-puppetdb
q_puppetdb_hostname=localhost
q_puppetdb_install=y
q_puppetdb_port=8081
q_puppetmaster_certname=localhost
q_puppetmaster_dnsaltnames=localhost,puppet
q_puppetmaster_enterpriseconsole_hostname=localhost
q_puppetmaster_enterpriseconsole_port=443
q_puppetmaster_install=y
q_run_updtvpkg=n
q_vendor_packages_install=y
EOF
  scp_to master, "#{host_os_tarball_dir}/#{pe_tarball_file}", '/root'
  create_remote_file master, '/root/answers.txt', answers
  on master, "cd /root; \
    tar -xf #{pe_tarball_file}; \
    cd #{pe_tarball_dir}; \
    ./puppet-enterprise-installer -a /root/answers.txt"
end
