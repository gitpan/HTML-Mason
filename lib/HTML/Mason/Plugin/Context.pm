package HTML::Mason::Plugin::Context;
BEGIN {
  $HTML::Mason::Plugin::Context::VERSION = '1.50';
}
use strict;
use warnings;

#------------------------------------------------------------

package HTML::Mason::Plugin::Context::StartRequest;
BEGIN {
  $HTML::Mason::Plugin::Context::StartRequest::VERSION = '1.50';
}
use base qw(HTML::Mason::Plugin::Context);

sub request   { $_[0]->[0] }
sub args      {
    if (wantarray) {
        return @{$_[0]->[1]};
    } else {
        return $_[0]->[1];
    }
}

#------------------------------------------------------------

package HTML::Mason::Plugin::Context::EndRequest;
BEGIN {
  $HTML::Mason::Plugin::Context::EndRequest::VERSION = '1.50';
}
use base qw(HTML::Mason::Plugin::Context);

sub request   { $_[0]->[0] }
sub args      {
    if (wantarray) {
        return @{$_[0]->[1]};
    } else {
        return $_[0]->[1];
    }
}
sub output    { $_[0]->[2] }
sub wantarray { $_[0]->[3] }
sub result    { $_[0]->[4] }
sub error     { $_[0]->[5] }

#------------------------------------------------------------

package HTML::Mason::Plugin::Context::StartComponent;
BEGIN {
  $HTML::Mason::Plugin::Context::StartComponent::VERSION = '1.50';
}
use base qw(HTML::Mason::Plugin::Context);

sub request   { $_[0]->[0] }
sub comp      { $_[0]->[1] }
sub args      { $_[0]->[2] }

#------------------------------------------------------------

package HTML::Mason::Plugin::Context::EndComponent;
BEGIN {
  $HTML::Mason::Plugin::Context::EndComponent::VERSION = '1.50';
}
use base qw(HTML::Mason::Plugin::Context);

sub request   { $_[0]->[0] }
sub comp      { $_[0]->[1] }
sub args      { $_[0]->[2] }
sub wantarray { $_[0]->[3] }
sub result    { $_[0]->[4] }
sub error     { $_[0]->[5] }

#------------------------------------------------------------

1;



=pod

=head1 NAME

HTML::Mason::Plugin::Context - encapsulates arguments passed to plugin methods

=head1 VERSION

version 1.50

=head1 DESCRIPTION

This file defines the minimalist context classes that are instantiated
whenever a plugin hook is called. See HTML::Mason::Plugin for
documentation about plugins.

For efficiency these objects have no new() method - they are created
and blessed by hand inside HTML::Mason::Request just before they are
used.

=head1 SEE ALSO

L<Mason|Mason>

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Ken Williams <ken@mathforum.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

