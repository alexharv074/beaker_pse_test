test_name 'Apply PSE solution' do

  nginx_tar_file_name = 'nginx.tar'
  nginx_tar_full_path = "#{ENV['HOME']}/git/beaker_pse_test/solution/#{nginx_tar_file_name}"
  expected_cksum = '2336431399'

  step 'Copy nginx module to modulepath on master'
  scp_to master, nginx_tar_full_path, '/root'
  on master, "cd /etc/puppetlabs/puppet/modules && tar -xf /root/#{nginx_tar_file_name}"

  step 'Classify default node with nginx on master'
  manifest = <<EOF
node default {
  include nginx
}
EOF
  create_remote_file master, '/etc/puppetlabs/puppet/manifests/site.pp', manifest

  step 'Run the puppet agent to apply nginx on client'
  on nginx, puppet_agent('-t'), :acceptable_exit_codes => 0

  step 'Get a file from nginx server on client'
  on nginx, 'curl -O http://localhost:8080/ -o /tmp/index.html'

  step 'Examine checksum of the received file'
  on nginx, 'cksum /tmp/index.html' do
    actual_cksum = stdout.sub('^(\d+) .*', match[1])
    assert_equal expected_cksum, actual_cksum, "File /tmp/index.html doesn't have the expected cksum"
  end

end
