
die "The Parser module is no longer a part of HTML::Mason.  Please see ".
    "the Lexer and Compiler modules, its replacements.\n";

1;  # heh

__END__

=pod

=head1 NAME

HTML::Mason::Parser - Old module for compiling components

=head1 VERSION

version 1.52

=head1 DESCRIPTION

The Parser object is no longer part of Mason.  It has been replaced by
the Compiler and Lexer objects.  See the L<Developer's
Manual|HTML::Mason::Devel> and the L<Administrator's
Manual|HTML::Mason::Admin> for more details.

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
