package HTML::EmbeddedPerl;
use strict;
use warnings;

use Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(ep);
our @EXPORT_OK = qw($VERSION $TIMEOUT);

our $VERSION = '0.02';
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
        my($l,$e) = ($@ =~ /line\x20([0-9]+)(.+)\s+$/);
        $l = $now + ($l - 1); chop $@;
        $@ =~ /^Force/ ? $@ =~ s/at\x20.+$/at\x20line\x20$now\x20or\x20after\x20that./ : $@ =~ s/at\x20\(.+$/at\x20line\x20$l$e/;
        $@ =~ s/\x22/\&quot\;/g;
        $tmp .= qq[\n<blockquote style="padding:4px;color:#c00;background-color:#fdd;border:solid 1px #f99;font-size:80%;"><span style="font-weight:bold;">ERROR:</span> $@</blockquote>\n];
        last;
      }
    } else{ $tmp .= $tag; }
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

I<automatic.>

=head2 run in the automatically

passing of instanced object B<$epl>.
example of use in the code tags.

  # output header ($key,$value)
  $epl->header_out('Content-Type','text/html');
  # set of contents type, default is 'text/html', output forcing.
  $epl->content_type('text/html');

=head2 using in the script

  $htm = I<something>;

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

  E<lt>FilesMatchE<quot>.*\.phtml?$E<quot>E<gt>
  SetHandler B<perl-script>
  PerlResponseHandler HTML::EmbeddedPerl
  PerlOptions +ParseHeaders
  E<lt>/FilesMatchE<gt>

=head2 cgi

inserting first line to

  #!/your/path/twepl

=head2 wrapper

if you cannot use twepl? but wrapper.pl is available.

  AddType application/x-embedded-perl .phtml
  AddHandler application/x-embedded-perl .phtml
  Action application/x-embedded-perl I</your/path/wrapper>

=head1 TIMEOUT

force exiting over the timeout for loop detection.
B<$TIMEOUT> is global, please change it overwritten.

  # default is E<quot>2E<quot> seconds.
  $TIMEOUT = 2;

already executing under alarm, cannot change that timeout.

  # set as new timeout.
  alarm($TIMEOUT);
  # cancelling timeout.
  alarm(0);

=head2 modperl2

  $TIMEOUT = B<X>;
  # cancelling timeout and unset timeout.
  alarm(($TIMEOUT=0));

=head2 cgi

  # set as new timeout.
  alarm(B<X>);

=head2 wrapper

before calling sub B<ep()>

  $HTML::EmbeddedPerl::TIMEOUT = B<X>;

=head1 RESERVED

  $TIMEOUT(global)
  $epl
  $var

=head1 AUTHOR

Twinkle Computing <twinkle@cpan.org>

=cut
