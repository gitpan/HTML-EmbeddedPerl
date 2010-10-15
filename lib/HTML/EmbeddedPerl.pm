package HTML::EmbeddedPerl;

#use strict;
#use warnings;

use Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(ep);
our @EXPORT_OK = qw($VERSION $TIMEOUT);

our $VERSION = '0.20';
our $TIMEOUT = 2;

use XSLoader;
XSLoader::load('HTML::EmbeddedPerl',$VERSION);

my $STDBAK = *STDOUT;

my $PKGNAM = __PACKAGE__;

my $CTTYPE = 'text/html';
my @HEADER = ();

sub _coloring{
  my($e,$c) = ($_[0],$_[1] ? $_[1] : '090');
  $c =~ s/^\x23//;
  $e =~ s/\&/\&amp;/go;
  $e =~ s/\x20/\&nbsp;/go;
  $e =~ s/\</\&lt;/go;
  $e =~ s/\>/\&gt;/go;
  $e =~ s/\"/\&quot;/go;
  $e =~ s/^[\r\n]*//go;
  $e =~ s/[\r\n]*$//go;
  $e =~ s/\r\n|[\r\n]/\<br\x20\/\>/go;
  $e =~ s/\\(?!\")/\\\\/go;
  $e =~ s/\$/\\\$/go;
  $e =~ s/\@/\\\@/go;
  $e =~ s/\%/\\\%/go;
  return qq[\$ep->print("<blockquote style=\\"color:#$c;\\">$e</blockquote>");];
}
sub _extract_hash{
  my($n,$t,$l) = @_;
  my $r = qq[{ my(\$c$l,\$n$l) = (scalar(keys \%$n),'$n'); foreach my \$k$l(keys \%$n){ my \$v$l = \$$n\{\$k$l\}; \$ep->print("$t"); }}];
  $r = qq["); $r \$ep->print("] if $l;
  return $r;
}
sub _extract_array{
  my($n,$t,$l) = @_;
  my $r = qq[{ my(\$c$l,\$n$l) = (scalar(\@$n),'$n'); for(my \$i=0;\$i<\@$n;\$i++){ \$_ = \$$n\x5b\$i\x5d; \$ep->print("$t"); }}];
  $r = qq["); $r \$ep->print("] if $l;
  return $r;
}
sub _extract_bool{
  my($x,$t,$l) = @_;
  my $r = qq[{ if($x){ \$ep->print("$t"); }}];
  $r =~ s/\<\!(\([^\)]+?\)|[^\>]+)\>/"); } elsif($1) { \$ep->print("/gos;
  $r =~ s/\<\!\>/"); } else { \$ep->print("/os;
  $r = qq["); $r \$ep->print("] if $l;
  return $r;
}
sub _extract_bool_unless{
  my($x,$t,$l) = @_;
  my $r = qq[{ unless($x){ \$ep->print("$t"); }}];
  $r =~ s/\<\!(\([^\)]+?\)|[^\>]+)\>/"); } elsif($1) { \$ep->print("/gos;
  $r =~ s/\<\!\>/"); } else { \$ep->print("/os;
  $r = qq["); $r \$ep->print("] if $l;
  return $r;
}
sub _extract_tags{
  my($i,$f,$l,$o) = (shift,shift,shift,'');
  foreach my $t(split(/(\<\\?\%(?:\w+|\{\w+\}|\\\w+)\>(?:.*(?:\<\\?\%(?:\w+|\{\w+\}|\\\w+)\>)?.+?(?:\<\/\%\>)?.*)+\<\/\%\>|\<\\?\@(?:\w+|\{\w+\}|\\\w+)\>(?:.*(?:\<\\?\@(?:\w+|\{\w+\}|\\\w+)\>)?.+?(?:\<\/\@\>)?.*)+\<\/\@\>|\<\=(?:\([^\)]+?\)|[^\>]+)\>(?:.*(?:\<\=(?:\([^\)]+?\)|[^\>]+)\>)?.+?(?:\<\/\=\>)?.*)+\<\/\=\>|\<\!(?:\([^\)]+?\)|[^\>]+)\>(?:.*(?:\<\!(?:\([^\)]+?\)|[^\>]+)>]+\>)?.+?(?:\<\/\!\>)?.*)+\<\/\!\>)/s,${$i})){
    if($t =~ s/\<\/\%\>$// && $t =~ s/^\<(\\)?\%(\w+)\>//){
      my $r = $1 ? $1 : ''; my $n = $1 ? "{\$$2}" : $2;
      $o .= _coloring("<$r\%$2>$t</\%>",'c0c') if ! $l && $f % 2;
      $t = _extract_tags(\$t,$f,1) if $t =~ /\<\\?[\=\!\@\%]/s;
      $o .= _extract_hash($n,$t,$l++); $l--;
    } elsif($t =~ s/\<\/\@\>$// && $t =~ s/^\<(\\)?\@(\w+)\>//){
      my $r = $1 ? $1 : ''; my $n = $1 ? "{\$$2}" : $2;
      $o .= _coloring("<$r\@$2>$t</\@>",'c00') if ! $l && $f % 2;
      $t = _extract_tags(\$t,$f,1) if $t =~ /\<\\?[\=\!\@\%]/s;
      $o .= _extract_array($n,$t,$l++); $l--;
    } elsif($t =~ s/\<\/\=\>$// && $t =~ s/^\<\=(\([^\)]+?\)|[^\>]+)\>//){
      my $x = $1;
      $o .= _coloring("<=$x>$t</=>",'00c') if ! $l && $f % 2;
      $t = _extract_tags(\$t,$f,1) if $t =~ /\<\\?[\=\!\@\%]/s;
      $o .= _extract_bool($x,$t,$l++); $l--;
    } elsif($t =~ s/\<\/\!\>$// && $t =~ s/^\<\!(\([^\)]+?\)|[^\>]+)\>//){
      my $x = $1;
      $o .= _coloring("<!$x>$t</!>",'09c') if ! $l && $f % 2;
      $t = _extract_tags(\$t,$f,1) if $t =~ /\<\\?[\=\!\@\%]/s;
      $o .= _extract_bool_unless($x,$t,$l++); $l--;
    } else{
      # output HTML code in debug
      #$o .= _coloring($t,'999') if ! $l && $f % 2;
      $o .= $l ? $t : qq[\$ep->print("$t");];
    }
  }
  return $o;
}
sub _re_print{
  my($r1,$r2,$r3,$r4,$r5,$r6,$r7,$r8,$r9) = @_;
  my $ret = "$r1\$ep->print($r2";
  $ret .= ')' if $3;
  $ret .= "$r4$r5$r6";
  $ret .= $r3 ? $r7 : "$r7$r8)$r9";
  return $ret;
}
sub _init{
  my($i,$f,$u,@o) = (ref $_[0] ? ${$_[0]} : $_[0],$_[1],$_[2]);
  if($i =~ s/^\#\![^\r\n]+([\r\n\s]+)//os){
    push(@o,$1);
  }
  foreach my $t(split(/(\<\$.+?\$\>|\<\:.+?\:\>)/s,$i)){
    if($t =~ s/^\<\$// && $t =~ s/\$\>$//){
      push(@o,_coloring($t)) if $f % 2;
      $t =~ s/(?<!\$ep\-\>)([\s\;])print\s*(?:[\$\*\w]*(?:\(\))?)\s*(q[qw]?|\<\<[\"\'\`]?(\w+))?([\(\[\{]?)(.)(.+?)(\3|\5)([\)\]\}])?(\;?)/_re_print($1,$2,$3,$4,$5,$6,$7,$8,$9)/egs if exists $ENV{MOD_PERL};
      $t = _ignore_comments($t);
      push(@o,$t);
    } elsif($t =~ s/^\<\:// && $t =~ s/\:\>$//){
      push(@o,_coloring($t)) if $f % 2;
      push(@o,$t);
    } else{
      my $y = $t =~ s/^(\s*)\<\!\-\-[yY]\-\-\>/$1/s;
      my $n = $t =~ s/^(\s*)\<\!\-\-[nN]\-\-\>/$1/s;
      $t =~ s/\"/\\\"/go;
      if(($u % 2 && ! $n || ! $u % 2 && $y)&&$t=~/\<[\=\!\\\@\%]/){
        $t = _extract_tags(\$t,$f,0);
        push(@o,$t);
      } else{
        push(@o,qq[print "$t";]);
      }
    }
  }
  return wantarray ? @o : join '',@o;
}

sub header_out{
  my($ki,$vi) = ref $_[0] eq $PKGNAM ? (1,2) : (0,1);
  if(exists $ENV{MOD_PERL}){
    $_[0]->header_out($_[1],$_[2]);
    return;
  }
  return if $_[$ki] =~ /Content\-Type/i;
  my $f = 0; for(my $i=0;$i<@HEADER;$i++){
    my($k,$v) = split /\: /,$HEADER[$i],2;
    if($k eq $_[$ki]){
      $HEADER[$i] = "$k: $_[$vi]" if($v ne $_[$vi]);
      $f++; last;
    }
  }
  push(@HEADER,"$_[$ki]: $_[$vi]") if(!$f);
}
sub header{
  my $h = ref $_[0] eq $PKGNAM ? $_[1] : $_[0]; my($k,$v) = split(/\:\s+/,$h,2); header_out($k,$v);
}
sub content_type{
  if(exists $ENV{MOD_PERL}){
    $_[0]->content_type($_[1]);
    return;
  }
  $CTTYPE = ref($_[0]) eq $PKGNAM ? $_[1] : $_[0];
}
sub flush{
  return if(exists $ENV{MOD_PERL});
  print $STDBAK (@HEADER ? join("\r\n",@HEADER)."\r\n":'')."Content-Type: $CTTYPE\r\n\r\n";
}
sub print{
  if(exists $ENV{MOD_PERL}){
    my $o = shift;
    $o->print(@_);
    return;
  }
  shift if ref $_[0] eq $PKGNAM; CORE::print @_;
}
sub echo{
  if(exists $ENV{MOD_PERL}){
    my $o = shift;
    $o->print(@_);
    return;
  }
  shift if ref $_[0] eq $PKGNAM; CORE::print @_;
}
sub printf{
  if(exists $ENV{MOD_PERL}){
    my $o = shift;
    $o->printf(@_);
    return;
  }
  shift if ref $_[0] eq $PKGNAM; CORE::printf @_;
}

sub _run{
  my($ep,$ev) = (shift,shift); return eval shift;
}

sub ep{
  my $ref = (ref $_[0] && ref($_[0]) =~ /^(Apa|$PKGNAM)/i)? shift : $PKGNAM->new();
  my $flg = $_[1] ? $_[1] : 0;
  my $ubf = $_[2] ? $_[2] : 0;
  my @src = _init((ref $_[0] ? ${$_[0]} : $_[0]),$flg,$ubf);
  my $tmp = '';
  my $var = bless {},$PKGNAM.'::Vars';
  open TMP,'>>',\$tmp;
  *STDOUT = *TMP;
  local $SIG{ALRM} = sub{ die 'Forced exiting, detected loop'; };
  alarm $TIMEOUT;
  if($flg > 3){
    $ref->content_type('text/plain');
    if($flg > 5){
      foreach my $ept(@src){
        $tmp .= '<:'.$ept.':>';
      }
    } else{
      $tmp .= '<:'.join('',@src).':>';
    }
  } elsif($flg > 1){
    my($pos,$now) = (1,0);
    foreach my $epl(@src){
      $now = $pos;
      $pos += $epl =~ s/\r\n|[\r\n]/\n/gs;
      if(!_run($ref,$var,$epl) && $@){
        $@ =~ s/at\x20\(eval\x20[0-9]+\)\x20line\x20([0-9]+)/'at line '.($now+($1-1))/ego;
        $@ =~ s/\x22/\&quot\;/g; chop $@;
        my $ret = qq[<blockquote style="padding:4px;color:#c00;background-color:#fdd;border:solid 1px #f99;font-size:80%;"><span style="font-weight:bold;">ERROR:</span> $@</blockquote>\n];
        if(exists $ENV{MOD_PERL}){ $ref->print($ret); }
        else{ $tmp .= $ret; }
        last if $@ =~ /^(Force|ModPerl\:\:Util\:\:exit)/;
      }
    }
  } else{
    if(!_run($ref,$var,join('',@src)) && $@){
      $@ =~ s/at\x20\(eval\x20[0-9]+\)\x20line\x20([0-9]+)/at line $1/go;
      $@ =~ s/\x22/\&quot\;/g; chop $@;
      my $ret = qq[<h3 style="color:#600;font-weight:bold;">Encountered 500 Internal Server Error</h3>\n\n];
      $ret .= qq[<blockquote style="padding:4px;color:#c00;background-color:#fdd;border:solid 1px #f99;font-size:80%;">$@</blockquote>\n];
      $ret .= qq[<hr style="border-style:solid;border-width:1px 0px 0px 0px;border-color:#900;" />\n];
      $ret .= qq[<div style="color:#600;text-align:right;">$ENV{SERVER_SIGNATURE}</div>\n];
      $ref->header_out('Status','500 Internal Server Error');
      if(exists $ENV{MOD_PERL}){ $ref->print($ret); }
      else{ $tmp .= $ret; }
    }
  }
  close TMP;
  *STDOUT = $STDBAK;
  return $tmp if defined wantarray;
  &flush if ref $ref eq $PKGNAM;
  $ref->print($tmp);
}

sub handler{
  my($r,$c) = (shift,'');
  my $f = exists $ENV{OUTMODE} ? $ENV{OUTMODE} : 0;
  my $u = exists $ENV{USEFEAT} ? $ENV{USEFEAT} : 0;
  $r->content_type('text/html');
  return 404 unless open HTM, $r->filename;
  sysread HTM,$c,(-s HTM);
  close HTM;
  ep $r,\$c,$f,$u;
  0;
}

sub new{
  my $s = bless {},shift;
  return $s;
}

1;

__END__

=head1 NAME

HTML::EmbeddedPerl - The Perl embeddings for HTML.

=head1 SYNOPSYS

I<automatic>.

B<option> is B<0-1>

  <$ my $test = 1; $>
  <$ print $test $> # OK

B<option> is B<2-3>

  <$ my $test = 1; $>
  <$ print $test $> # NG

  <$ use vars qw($test); $test = 1; $ev::test = 1; $>
  <$ print $test $> # OK
  <$ print $ev::test $> # OK

=head2 run in the automatically

passing of instanced object B<$ep>.
that are reference of B<Apache::RequestRec>I<(modperl)> or B<__PACKAGE__>I<(cgi)>.
example of use in the code tags.

  # set output header ($key,$value)
  $ep->header_out('Content-Create','foo');
  # set of contents type, default is 'text/html', output forcing.
  $ep->content_type('text/plain');

if you want not use of global variables, please use B<$ev>.
destruct B<$ev> after execute.
but it can use between multiple tags too.

=head2 using in the script

  $htm = something;

  use HTML::EmbeddedPerl;
  $e = HTML::EmbeddedPerl->new();

  # set output header ($key,$value)
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

=head2 mod_perl2

write B<httpd.conf> or B<.htaccess>.

  <FilesMatch ".*\.phtml?$">
  # Output Mode - 0..5, see OPTIONS section.
  PerlSetEnv OUTMODE 0
  # Template Mode - 0..1, see OPTIONS section.
  PerlSetEnv USEFEAT 0
  SetHandler modperl
  PerlResponseHandler HTML::EmbeddedPerl
  PerlOptions +ParseHeaders
  </FilesMatch>

needs most compatibility, use I<PerlResponseHandler perl-script>.
*please do not use B<CORE::print>. (or call B<$ep->rflush()> needed)

=head2 CGI

inserting first line to

  #!/your/path/twepl

=head2 Wrapper

if you cannot use twepl? but wrapper.pl is available.
write B<.htaccess>.

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
  alarm(X);
  # cancelling timeout.
  alarm(0);

=head2 mod_perl2

  # set as new timeout.
  alarm(($TIMEOUT=X));
  # cancelling timeout and unset timeout.
  alarm(($TIMEOUT=0));

=head2 CGI

  # set as new timeout.
  alarm(X);

=head2 Wrapper

before calling sub B<ep()>

  $HTML::EmbeddedPerl::TIMEOUT = X;

=head1 INTERNAL METHODS

  _coloring
  _extract_hash
  _extract_array
  _extract_bool
  _extract_bool_unless
  _extract_tags
  _get_crlf
  _ignore_comments
  _init
  _run

  handler

=head1 BASIC METHODS

=head2 ep

  ep($string,$option);

=head2 new

  $ep = HTML::EmbeddedPerl->new();

=head1 METHODS FOR CGI

=head2 flush

flushing HTTP header.

  $ep->flush;

=head2 header

PHP like method.

  header("$key: $val");

=head2 echo

PHP like method.

  echo $string;

=head1 COMPATIBLE METHODS

it tiny-tiny solving B<cgi>-B<modperl> compatibility methods.

=head2 header_out

  $ep->header_out($key,$val);

=head2 content_type

  $ep->content-type($type);

=head2 print

  $ep->print($string);

=head2 printf

  $ep->print($format,$string);

=head1 OTHER METHODS

other methods define it freely.

=head2 mod_perl2

depends B<Apache::RequestRec> and more.

=head1 EXPORTS

ep(B<string>,B<option1>,B<option2>)

=head1 OPTIONS

ep(B<string>,B<option1>,B<option2>)

=head2 OPTION 1

B<0> = default, execute only once.
B<1> =  I<-- with coloring source>.
B<2> = older version compatible, every tags execute.
B<3> =  I<-- with coloring source>.
B<4> = output internal code.
B<5> =  I<-- with coloring source>.
B<6> = output internal code to multiple-tags.
B<7> =  I<-- with coloring source>.

=head2 OPTION 2

B<0> = default, B<not> template mode.
B<1> = template mode.I<(use beta features)>

=head1 COMMENTS

B<#> comments
B<//> comments
B</*> comments B<*/>

=head1 Extract Vars

case of extract scalar in non-code blocks.

  <$ my $scalar = 'this is scalar'; $>
  <p>$scalar</p>
  ...
  <p>this is scalar</p>

  <$ my @array = (1..3); $>
  <p>@array</p>
  ...
  <p>1 2 3</p>

if you want not extract vars, please use escape sequence B<'\'>.

  <p>\$scalar</p>
  <p>\@array</p>
  ...
  <p>$scalar</p>
  <p>@array</p>

and available simple template.

=head1 BETA Features

use this beta features needs set option.
or insert as first element in non-code blocks it.

B<<!--Y-->>
B<<!--N-->>

default is B<off>, because it was very slow.

=head2 Extract Array

<@B<ARRAYNAME>>...</@> or <\@B<ARRAYREFNAME>>...</@>, extract value is B<$_>.

B<X> is nested depth.

B<$nX> = current array name.
B<$iX> = current position.
B<$cX> = equals scalar @array;

and B<$XXX> = want vars.

  <$ my @array = ('a'..'c'); $>
  <@array><p>$i: $_</p>\n</@>
  ...
  <p>0: a</p>
  <p>1: b</p>
  <p>2: c</p>

=head2 Extract Hash

<%B<HASHNAME>>...</%> or <\%B<HASHREFNAME>>...</%>, extract key is B<$kX>, value is B<$vX>.

B<X> is nested depth.

B<$nX> = current hash name.
B<$cX> = equals scalar keys %hash;

and B<$XXX> = want vars.

  <$ my %hash = ('a'=>1,'b'=>2,'c'=>3); $>
  <table>
  <%hash><tr><th>$k0</th><td>$v0</td></tr>\n</%>
  </table>
  ...
  <table>
  <tr><th>a</th><td>1</td><tr>
  <tr><th>b</th><td>2</td><tr>
  <tr><th>c</th><td>3</td><tr>
  </table>

=head2 Boolean Expression

<B<EXPRESSION>>...</=> or B<unless> <!B<EXPRESSION>>...</!>
replace inner B<<!>> to else, <!B<EXPRESSION>> to elsif.

  <$ my $flag = 1; my $oops = 'oops!'; $>
  <=$flag><p>$flag</p><!><p>$oops</p></=>
  ...
  <p>1</p>

B<E<gt>> is same a tag-closer, try B<($a E<gt> $b)> in compilation errors.

=head1 AUTHOR

TWINKLE COMPUTING <twinkle@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010 TWINKLE COMPUTING All rights reserved.

=head1 LISENCE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
