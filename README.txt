Contents of this repository:

examples/beaker101:

  This directory contains the example documented at:
  https://confluence.puppetlabs.com/display/DEL/Beaker+101

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

examples/simple3:

  This example is identical with simple1 and simple2 except that the PE tarball is both assumed to
  be found in the host OS in /var/tmp, and it is installed without using the built-in install_pe
  method.

  To run this example:

  1)  Make sure puppet-enterprise-3.1.0-el-6-x86_64.tar.gz is in /var/tmp.

  2)  Change to the examples/simple3 directory.

  3)  Run:
  $ beaker --debug --hosts hosts.cfg --pre-suite pre-suite.rb --tests tests.rb

examples/pse_test1:

  This example applies the PSE test solution on a single host that will run both the Puppet Master
  and nginx server.  The solution is modified to use port 8082 so as not to conflict with the
  Puppet Master's use of port 8080.

  To run this example:

  1)  Change to the examples/pse_test1 directory

  2)  Run:
  $ beaker --hosts hosts.cfg --pre-suite pre-suite.rb --tests tests.rb
