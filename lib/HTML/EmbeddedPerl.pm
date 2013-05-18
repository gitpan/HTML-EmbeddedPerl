package HTML::EmbeddedPerl;

use strict;
use warnings;

use Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(headers_out header content_type echo $VERSION);

our $VERSION = '0.90';

our %HEADER;
our $CONTYP = 'text/html';

our $STIBAK;
our $STITMP;
our $STIBUF;
our $STOBAK;
our $STOTMP;
our $STOBUF;

use XSLoader;
XSLoader::load('HTML::EmbeddedPerl', $VERSION);

sub handler{
  my $r = shift;
  my $t = _twepl_handler($r->filename);
  foreach my $e(sort keys %HEADER){
    $r->headers_out($e, $HEADER{$e});
  }
  $r->content_type($CONTYP);
  $r->puts($t);
  $r->flush();
  200;
}

1;

__END__

=head1 NAME

HTML::EmbeddedPerl - The Perl embeddings for HTML.

=head1 SYNOPSYS

I<automatic> for mod_perl2.

=head1 DESCRIPTION

The Perl source code embeddings for HTML.

adding I<E<lt>?(p5|pl|pl5|perl|perl5)? Perl-Code ?E<gt>> to your HTML.

=head1 AUTHOR

TWINKLE COMPUTING <twinkle@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010 TWINKLE COMPUTING All rights reserved.

=head1 LISENCE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
