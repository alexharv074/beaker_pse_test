Contents of this repository:

examples/beaker101:

  This directory contains the example documented at:
  https://confluence.puppetlabs.com/display/DEL/Beaker+101

examples/manual_install:

  This directory contains a simple example of a Beaker script that uses Beaker
  to install PE 3.1.0 manually on a CentOS 6 VM, by installing from the tarball
  puppet-enterprise-3.1.0-el-6-x86_64.tar.gz 

  To run this example:

  1)  Download:
  https://s3.amazonaws.com/pe-builds/released/3.1.0/puppet-enterprise-3.1.0-el-6-x86_64.tar.gz
  and save it in $HOME.

  2)  Change to the examples/manual_install directory.

  3)  Run:
  $ beaker --debug --hosts hosts.cfg --pre-suite pre-suite.rb --tests tests.rb

examples/simple1:

  This example installs PE 3.1.0 from
  https://s3.amazonaws.com/pe-builds/released/3.1.0/puppet-enterprise-3.1.0-el-6-x86_64.tar.gz,
  applies a simple Puppet manifest that puts 'Hello World!' in a file, and then applies a test
  to check that the file contains the expected content.

  To run this example:

  1)  Change to the examples/simple1 directory.

  2)  Run:
  $ beaker --debug --hosts hosts.cfg --pre-suite pre-suite.rb --tests tests.rb

examples/simple2:

  This example is identical with simple1 except that the PE tarball is assumed to be found in the
  host OS in /var/tmp.

  To run this example:

  1)  Make sure puppet-enterprise-3.1.0-el-6-x86_64.tar.gz is in /var/tmp.

  2)  Change to the examples/simple2 directory.

  3)  Run:
  $ beaker --debug --hosts hosts.cfg --pre-suite pre-suite.rb --tests tests.rb
