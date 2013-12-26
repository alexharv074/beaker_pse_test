test_name 'Apply simple manifest' do
  manifest = <<EOF
file { '/tmp/foo':
  ensure => file,
  content => "Hello world!\n",
}
EOF
  apply_manifest_on master, manifest
  on master, 'cat /tmp/foo' do
    assert_equal "Hello world!", stdout.chomp, "File /tmp/foo doesn't contain expected content"
  end
end
