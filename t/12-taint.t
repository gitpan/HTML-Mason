#!/usr/bin/perl -wT

use strict;

BEGIN
{
    # Cwd in taint mode spits out weird errors with older Perls and
    # may or may not work at all
    if ( $] < 5.006 )
    {
        print "1..0\n";
        exit;
    }

    $ENV{PATH} = '';
}

# Cwd has to be loaded after sanitizing $ENV{PATH}
use Cwd;
use File::Spec;
use Test;

BEGIN
{
    my $curdir = File::Spec->curdir;

    my $libs = 'use lib qw( ';
    $libs .=
        ( join ' ',
          File::Spec->catdir( $curdir, 'blib', 'lib' ),
          File::Spec->catdir( $curdir, 't', 'lib' )
        );

    if ($ENV{PERL5LIB})
    {
	$libs .= ' ';
	$libs .= join ' ', (split /:|;/, $ENV{PERL5LIB});
    }
    $libs .= ' );';

    ($libs) = $libs =~ /(.*)/;

    # explicitly use these because otherwise taint mode causes them to
    # be ignored
    eval $libs;
}

use HTML::Mason::Interp;
use HTML::Mason::Compiler::ToObject;
use HTML::Mason::Tools qw(read_file taint_is_on);

# Clear alarms, and skip test if alarm not implemented
my $alarm_works = eval {alarm 0; 1};
plan tests => 8 + $alarm_works;

# These tests depend on taint mode being on
ok taint_is_on();

if ($alarm_works)
{
    my $compiler = HTML::Mason::Compiler::ToObject->new;

    my $alarm;
    $SIG{ALRM} = sub { $alarm = 1; die "alarm"; };

    my $comp = read_file( File::Spec->catfile( File::Spec->curdir, 't', 'taint.comp' ) );
    eval { alarm 5;
           local $^W;
           $comp = $compiler->compile( comp_source => $comp, name => 't/taint.comp' );
       };

    my $error = ( $alarm ? "entered endless while loop" :
		  $@ ? "gave error during test: $@" :
		  !defined($comp) ? "returned an undefined value from compiling" :
		  '' );
    ok $error, '';
}

# Make these values untainted
my ($comp_root) = File::Spec->catdir( getcwd(), 'mason_tests', 'comps' ) =~ /(.*)/;
my ($data_dir)  = File::Spec->catdir( getcwd(), 'mason_tests', 'data'  ) =~ /(.*)/;
ok !is_tainted($comp_root);
ok !is_tainted($data_dir);

my $interp = HTML::Mason::Interp->new( comp_root => $comp_root,
				       data_dir => $data_dir,
				     );

$data_dir = File::Spec->catdir( getcwd(), 'mason_tests', 'data' );

# This source is tainted, as is anything with return val from getcwd()
my $comp2 = HTML::Mason::ComponentSource->new
    ( friendly_name => 't/taint.comp',
      source_callback => sub {
	  read_file( File::Spec->catfile( File::Spec->curdir, 't', 'taint.comp' ) );
      },
    );
ok $comp2;
ok is_tainted($comp2->comp_source);

# Make sure we can write tainted data to disk
eval { $interp->compiler->compile_to_file
	   ( file => File::Spec->catfile( $data_dir, 'taint_write_test' ),
	     source => $comp2,
	   ); };
ok $@, '', "Unable to write a tainted object to disk";


my $cwd = getcwd(); # tainted
# This isn't a part of the documented interface, but we test it here anyway.
my $code = "# MASON COMPILER ID: ". $interp->compiler->object_id ."\nmy \$x = '$cwd';"; # also tainted
ok is_tainted($code);

eval { $interp->eval_object_code( object_code => \$code ) };
ok $@, '', "Unable to eval a tainted object file";

###########################################################
sub is_tainted {
  return not eval { "+@_" && kill 0; 1 };
}
