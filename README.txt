Contents of this repository:

examples/beaker101:

  This directory contains the example documented at:
  https://confluence.puppetlabs.com/display/DEL/Beaker+101

examples/manual_install:

  This directory contains a simple example that uses Beaker to install PE 3.1.0
  manually on a CentOS 6 VM, by installing the tarball
  puppet-enterprise-3.1.0-el-6-x86_64.tar.gz 

  To run this example:

  1)  Download:
  https://s3.amazonaws.com/pe-builds/released/3.1.0/puppet-enterprise-3.1.0-el-6-x86_64.tar.gz
  and save it in $HOME.

  2)  Change to the examples/manual_install directory.

  3)  Run:
  $ beaker --debug --hosts hosts.cfg --pre-suite pre-suite.rb --tests tests.rb
