
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "High-performance, dynamic web site authoring system",
  "AUTHOR" => "Jonathan Swartz <swartz\@pobox.com>, Dave Rolsky <autarch\@urth.org>, Ken Williams <ken\@mathforum.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-Mason",
  "EXE_FILES" => [
    "bin/convert0.6.pl",
    "bin/convert0.6.README",
    "bin/convert0.8.pl",
    "bin/convert0.8.README",
    "bin/mason.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "HTML::Mason",
  "PREREQ_PM" => {
    "CGI" => "2.46",
    "Cache::Cache" => "1.00",
    "Class::Container" => "0.07",
    "Exception::Class" => "1.15",
    "File::Spec" => "0.8",
    "HTML::Entities" => 0,
    "Log::Any" => "0.08",
    "Params::Validate" => "0.70",
    "Scalar::Util" => "1.01"
  },
  "TEST_REQUIRES" => {
    "Test::Deep" => 0
  },
  "VERSION" => "1.53",
  "test" => {
    "TESTS" => "t/*.t t/author-live/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



