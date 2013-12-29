test_name 'Apply PSE solution' do

  nginx_tar_file_name = 'nginx.tar'
  nginx_tar_full_path = "#{ENV['HOME']}/git/beaker_pse_test/solution/#{nginx_tar_file_name}"
  expected_cksum = '2336431399'

  step 'Copy nginx module to modulepath on master'
  scp_to master, nginx_tar_full_path, '/root'
  on master, "cd /etc/puppetlabs/puppet/modules; tar -xf /root/#{nginx_tar_file_name}"

  step 'Apply the nginx manifest'
  on master, puppet_apply('/etc/puppetlabs/puppet/modules/nginx/tests/init.pp')

  step 'Get a file from nginx server on client'
  on master, 'cd /tmp; wget http://localhost:8082/'

  step 'Examine checksum of the received file'
  on master, 'cksum /tmp/index.html' do
    actual_cksum = stdout.chomp.sub(/^(\d+) .*/, '\1')
    assert_equal expected_cksum, actual_cksum, "File /tmp/index.html doesn't have the expected cksum"
  end

end
