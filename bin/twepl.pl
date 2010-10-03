package twepl;

use strict;
use warnings;

our $VERSION = '0.11';
our $TIMEOUT = 2;

my $STDBAK = *STDOUT;

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
  return qq[print "<blockquote style=\\"color:#$c;\\">$e</blockquote>";];
}
sub _extract_hash{
  my($n,$t,$l) = @_;
  my $r = qq[{ my(\$c,\$n) = (scalar(keys \%].$n.qq[),'$n'); foreach my \$k(keys \%].$n.qq[){ my \$v = \$].$n.qq[{\$k}; print "$t"; }};];
  $r = qq["; $r print "] if $l;
  return $r;
}
sub _extract_array{
  my($n,$t,$l) = @_;
  my $r = qq[{ my(\$c,\$n) = (scalar(\@$n),'$n'); for(my \$i=0;\$i<\@$n;\$i++){ \$_ = \$].$n.qq[[\$i]; print "$t"; }};];
  $r = qq["; $r print "] if $l;
  return $r;
}
sub _extract_bool{
  my($x,$t,$l) = @_;
  my $r = qq[{ if($x){ print "$t" }};];
  $r =~ s/\<\!\=([^\>]+)\>/"; } elsif($1) { print "/gos;
  $r =~ s/\<\!\>/"; } else { print "/os;
  $r = qq["; $r print "] if $l;
  return $r;
}
sub _extract_tags{
  my($i,$f,$l,@o) = (shift,shift,shift);
  foreach my $t(split(/(\<\%\=(?:\w+|\{\w+\}|\\\w+)\>(?:.*(?:\<\%=(?:\w+|\{\w+\}|\\\w+)\>)?.+?(?:\<\/\%\>)?.*)+\<\/\%\>|\<\@\=(?:\w+|\{\w+\}|\\\w+)\>(?:.*(?:\<\@=(?:\w+|\{\w+\}|\\\w+)\>)?.+?(?:\<\/\@\>)?.*)+\<\/\@\>|\<\!\=[^\>]+\>(?:.*(?:\<\!=[^\>]+\>)?.+?(?:\<\/\!\>)?.*)+\<\/\!\>)/os,$i)){
    $t =~ s/\"/\\\"/g;
    if($t =~ s/\<\/\%\>$// && $t =~ s/^\<\%\=(\w+|\{\w+\}|\\\w+)\>//){
      my $n = $1;
      push(@o,_coloring("<\%=$n>$t</\%>",'c0c')) if ! $l && $f % 2;
      $t = _extract_tags($t,$f,1) if $t =~ /\<([\@\%\!])\=(\([^\)]+\)|[^\>]+)\>.+\<\/\1\>/;
      $n =~ s/^\{(\w+)\}$/{\$$1}/;
      $n =~ s/^\\(\w+)$/{\$$1}/;
      push(@o,_extract_hash($n,$t,$l));
    } elsif($t =~ s/\<\/\@\>$// && $t =~ s/^\<\@\=(\w+|\{\w+\}|\\\w+)\>//){
      my $n = $1;
      push(@o,_coloring("<\@\=$n>$t</\@>",'c00')) if ! $l && $f % 2;
      $t = _extract_tags($t,$f,1) if $t =~ /\<([\@\%\!])\=(\([^\)]+\)|[^\>]+)\>.+\<\/\1\>/;
      $n =~ s/^\{(\w+)\}$/{\$$1}/;
      $n =~ s/^\\(\w+)$/{\$$1}/;
      push(@o,_extract_array($n,$t,$l));
    } elsif($t =~ s/\<\/\!\>$// && $t =~ s/^\<\!\=(\([^\)]+\)|[^\>]+)\>//){
      my $x = $1;
      push(@o,_coloring("<\!=$x>$t</\!>",'00c')) if ! $l && $f % 2;
      $t = _extract_tags($t,$f,1) if $t =~ /\<([\@\%\!])\=(?:\([^\)]+\)|[^\>]+)\>.+\<\/\1\>/;
      push(@o,_extract_bool($x,$t,$l));
    } else{
      push(@o,$l ? $t : qq[\$ep->print("$t");]);
    }
  }
  return wantarray ? @o : join '',@o;
}
sub _get_crlf{
  my $c = shift;
  $c =~ s/[^\r\n]//gs;
  return $c;
}
sub _ignore_comments{
  my($i,@o) = shift;
  foreach my $t(split(/(\<\<[\"\'\`]?(\w+).+?\2)/s,$i)){
    if($t =~ /^\w+$/){
      next;
    } elsif($t =~ /^\<\<[\"\'\`]?\w+/){
      push(@o,$t);
    } else{
      $t =~ s/\x20*\/\*(.+?)\*\/\x20*/_get_crlf($1)/egos;
      $t =~ s/(((?:qq?).|[\x22\x27\(\)\[\]\{\}]).*)[\x20]+?(\x23|\/\/).*(?!\1).*/$1/go;
      push(@o,$t);
    }
  }
  return wantarray ? @o : join '',@o;
}
sub _init{
  my($i,$f,@o) = (ref $_[0] ? ${$_[0]} : $_[0],$_[1]);
  my($d);
  foreach my $t(split(/(\<\$.+?\$\>)/s,$i)){
    if($t =~ s/^\<\$// && $t =~ s/\$\>$//m){
      push(@o,_coloring($t)) if $f % 2;
      $t = _ignore_comments($t);
      push(@o,$t);
    } else{
      $t = _extract_tags($t,$f,0);
      push(@o,$t);
    }
  }
  return wantarray ? @o : join '',@o;
}

sub header_out{
  my $f = 0; for(my $i=0;$i<@{$_[0]->{head}};$i++){
    my($k,$v) = split /\: /,@{$_[0]->{head}}[$i],2;
      if($k eq $_[1]){
      @{$_[0]->{head}}[$i] = "$k: $_[2]" if($v ne $_[2]);
      $f++; last;
    }
  }
  push(@{$_[0]->{head}},"$_[1]: $_[2]") if(!$f);
}
sub content_type{
  $_[0]->{type} = $_[1];
}
sub flush{
  print $STDBAK (@{$_[0]->{head}} ? join("\r\n",@{$_[0]->{head}})."\r\n":'')."Content-Type: $_[0]->{type}\r\n\r\n";
}
sub print{
  shift if ref $_[0] eq __PACKAGE__; CORE::print @_;
}

sub _run{
  my($ep,$ev) = (shift,shift); return eval shift;
}

sub main{
  my $pkg = __PACKAGE__;
  my $ref = bless {},$pkg;
  $ref->{type} = 'text/html';
  $ref->{head} = [];
  my $flg = 0;
  my($pos,$now) = (1,0);
  my $htm = '';
  foreach my $arg(@_){
    if($arg =~ /^\-([ceo]+)$/i){
      my $opt = $1;
      $flg += 4 if $opt =~ /c/ && $flg < 4;
      $flg += 2 if $opt =~ /e/ && $flg < 2;
      $flg += 1 if $opt =~ /o/ && !($flg % 2);
    } elsif($arg =~ /^\-t[\=\:]?([0-9]+)$/i){
      $TIMEOUT = int($1);
    } elsif(-f $arg){
      open HTM,$arg;
      my $imp;
      read HTM,$imp,(-s HTM);
      close HTM;
      $pos += $imp =~ s/^\#\![^\r\n]+(\r\n|[\r\n])//;
      $pos += $imp =~ s/^(\r\n|[\r\n])//gos;
      $htm .= $imp;
    }
  }
  unless($htm){
    print STDOUT "twepl: no input files.\n";
    exit;
  }
  my @src = _init($htm,$flg);
  my $tmp = '';
  my $var = bless {},$pkg.'::Vars';
  open TMP,'>>',\$tmp;
  *STDOUT = *TMP;
  $flg > 3 ? do {
    $tmp .= '<$'.join('',@src)."\$>\n";
    if(exists $ENV{DOCUMENT_ROOT}){
      $ref->content_type('text/plain');
    } else{
      print $STDBAK $tmp;
      exit;
    }
  } : $flg > 1 ? do {
    local $SIG{ALRM} = sub{ die 'Forced exiting, detected loop'; };
    alarm $TIMEOUT;
    foreach my $epl(@src){
      $now = $pos;
      $pos += $epl =~ s/\r\n|[\r\n]/\n/gs;
      if(!_run($ref,$var,$epl) && $@){
        $@ =~ s/at\x20\(eval\x20[0-9]+\)\x20line\x20([0-9]+)/'at line '.($now+($1-1))/ego;
        $@ =~ s/\x22/\&quot\;/g; chop $@;
        $tmp .= qq[<blockquote style="padding:4px;color:#c00;background-color:#fdd;border:solid 1px #f99;font-size:80%;"><span style="font-weight:bold;">ERROR:</span> $@</blockquote>\n];
        last if $@ =~ /^Force/;
      }
    }
  } : do {
    $now = $pos;
    local $SIG{ALRM} = sub{ die 'Forced exiting, detected loop'; };
    alarm $TIMEOUT;
    if(!_run($ref,$var,join('',@src)) && $@){
      $@ =~ s/at\x20\(eval\x20[0-9]+\)\x20line\x20([0-9]+)/'at line'.($now+($1-1))/ego;
      $@ =~ s/\x22/\&quot\;/g; chop $@;
      $tmp .= qq[<h3 style="color:#600;font-weight:bold;">Encountered 500 Internal Server Error</h3>\n\n];
      $tmp .= qq[<blockquote style="padding:4px;color:#c00;background-color:#fdd;border:solid 1px #f99;font-size:80%;">$@</blockquote>\n];
      $tmp .= qq[<hr style="border-style:solid;border-width:1px 0px 0px 0px;border-color:#900;" />\n];
      $tmp .= qq[<div style="color:#600;text-align:right;">$ENV{SERVER_SIGNATURE}</div>\n];
      $ref->header_out('Status','500 Internal Server Error');
    }
  };
  close TMP;
  *STDOUT = $STDBAK;
  flush $ref;
  print $tmp;
}
