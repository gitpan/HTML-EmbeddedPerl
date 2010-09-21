package HTML::EmbeddedPerl;
use strict;
use warnings;

use Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(ep);
our @EXPORT_OK = qw($VERSION $TIMEOUT);

our $VERSION = '0.06';
our $TIMEOUT = 2;

my $STDBAK = *STDOUT;

sub header_out{
  $_[0]->{head} .= "$_[1]: $_[2]\r\n";
}
sub content_type{
  $_[0]->{type} = $_[1];
}
sub flush{
  print $STDBAK "$_[0]->{head}Content-Type: $_[0]->{type}\r\n\r\n";
}
sub print{
  shift; CORE::print @_;
}
sub run{
  my($epl,$var) = (shift,shift);
  return eval shift;
}

sub ep{
  my $pkg = __PACKAGE__;
  my $ref = ref $_[0] ? shift : $pkg->new();
  my $src = ref $_[0] ? ${$_[0]} : $_[0];
  my $var = bless {},$pkg.'::Vars';
  my($pos,$now,$tmp) = (1,0,'');
  open TMP,'>>',\$tmp;
  *STDOUT = *TMP;
  local $SIG{ALRM} = sub{ die 'Forced exiting, detected loop'; };
  alarm $TIMEOUT;
  foreach my $tag(split(/(\<\$.+?)\$\>/s,$src)){
    $now = $pos;
    $pos += $tag =~ s/\r\n|[\r\n]/\n/gs;
    if($tag =~ s/^\<\$//){
      if(!run($ref,$var,$tag) && $@){
        $@ =~ /^Force/ ? $@ =~ s/at\x20.+$/at\x20line\x20$now\x20or\x20after\x20that\./ : $@ =~ s/at\x20\(eval\x20[0-9]+\)\x20line\x20([0-9]+)/'at line '.($now+($1-1))/eg;
        $@ =~ s/\x22/\&quot\;/g; chop $@;
        $tmp .= qq[\n<blockquote style="padding:4px;color:#c00;background-color:#fdd;border:solid 1px #f99;font-size:80%;"><span style="font-weight:bold;">ERROR:</span> $@</blockquote>\n];
        last;
      }
    } else{
      $tag =~ s/(?<![\\\$])(\$((::)?\w+|\[[\x22\x27]?\w+[\x22\x27]?\]|(->)?\{[\x22\x27]?\w+[\x22\x27]?\})+)/eval($1).(($@)?$1:'')/eg;
      $tag =~ s/\\\$/\$/g;
      $tmp .= $tag;
    }
  }
  close TMP;
  *STDOUT = $STDBAK;
  return $tmp if defined wantarray;
  flush $ref if ref $ref eq $pkg;
  $ref->print($tmp);
}

sub handler{
  my($r,$c) = (shift,'');
  $r->content_type('text/html');
  return 1 unless open HTM, $r->filename;
  sysread HTM,$c,(-s HTM);
  close HTM;
  ep $r,\$c;
  0;
}

sub new{
  my $s = bless {},shift;
  $s->{type} = 'text/html';
  $s->{head} = '';
  $s;
}

1;

=head1 NAME

HTML::EmbeddedPerl - The Perl embeddings for HTML.

=head1 SYNOPSYS

recommends run on I<automatic>.

=head2 run in the automatically

passing of instanced object B<$epl>.
that are reference of B<Apache::RequestRec>I<(modperl)> or B<__PACKAGE__>I<(cgi)>.
example of use in the code tags.

  # output header ($key,$value)
  $epl->header_out('Content-Type','text/html');
  # set of contents type, default is 'text/html', output forcing.
  $epl->content_type('text/html');

=head2 using in the script

  $htm = something;

  use HTML::EmbeddedPerl;
  $e = HTML::EmbeddedPerl->new();

  # output header ($key,$value)
  $e->header_out('Content-Create','foo');
  # set of contents type, default is 'text/html'
  $e->content_type('text/plain');

  # flushing header and contents. (example 1)
  $e->ep(\$htm);

  # not flushing header, return contents to $r.
  $r = $e->ep(\$htm);

  # flushing HTTP header.
  $e->flush;
  # same above. (example 1)
  print $r;

=head1 DESCRIPTION

The Perl-Code embeddings for HTML, it is simple and easy.

adding I<E<lt>$ Perl-Code $E<gt>> to your HTML.
if code blocks too many, cannot use local variables between code blocks.

=head2 modperl2

if you want not use of global variables, please use B<$var>.
destruct B<$var> after execute.
but it can use between multiple tags too.

  <FilesMatch ".*\.phtml?$">
  SetHandler modperl
  PerlResponseHandler HTML::EmbeddedPerl
  PerlOptions +ParseHeaders
  </FilesMatch>

for most compatibility, use I<PerlResponseHandler perl-script>.

=head2 cgi

inserting first line to

  #!/your/path/twepl

=head2 wrapper

if you cannot use twepl? but wrapper.pl is available.

  AddType application/x-embedded-perl .phtml
  AddHandler application/x-embedded-perl .phtml
  Action application/x-embedded-perl /your/path/wrapper

=head1 TIMEOUT

force exiting over the timeout for loop detection.
B<$TIMEOUT> is global, please change it overwritten.

  # default is "2" seconds.
  $TIMEOUT = 2;

already executing under alarm, cannot change that timeout.

  # set as new timeout.
  alarm($TIMEOUT);
  # cancelling timeout.
  alarm(0);

=head2 modperl2

  $TIMEOUT = X;
  # cancelling timeout and unset timeout.
  alarm(($TIMEOUT=0));

=head2 cgi

  # set as new timeout.
  alarm(X);

=head2 wrapper

before calling sub B<ep()>

  $HTML::EmbeddedPerl::TIMEOUT = X;

=head1 BETA Features

replace variables on non-code blocks. I<(not a reference) scalar> only.

=head1 RESERVED

it tiny-tiny solving B<cgi>-B<modperl> compatibility.

=head2 Subroutines

base.

  ep
  handler
  new

for cgi interface.
other B<Subs> define it freely.

  header_out
  content_type
  print
  flush

for modperl, run in the depends B<Apache::RequestRec> and more.

=head2 Variables

  $TIMEOUT(global)
  $epl
  $var

=head1 AUTHOR

Twinkle Computing <twinkle@cpan.org>

=head1 LISENCE

Copyright (c) 2010 Twinkle Computing All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
