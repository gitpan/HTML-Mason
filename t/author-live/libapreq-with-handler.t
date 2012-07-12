
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

use File::Spec;
use lib 'lib', File::Spec->catdir( 't', 'lib' );

use Mason::ApacheTest qw( require_libapreq );

require_libapreq();

Mason::ApacheTest->run_tests(
    apache_define => 'mod_perl',
    with_handler  => 1,
    test_sets     => [qw( standard apache_request )],
);
