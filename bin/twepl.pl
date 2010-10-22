#!/usr/bin/perl

package twepl;

#use strict;
#use warnings;

our $VERSION = '0.21';
our $TIMEOUT = 2;

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
  return qq[print "<blockquote style=\\"color:#$c;\\">$e</blockquote>";];
}
sub _extract_hash{
  my($n,$t,$l) = @_;
  my $r = qq[{ my(\$c$l,\$n$l) = (scalar(keys \%$n),'$n'); foreach my \$k$l(keys \%$n){ my \$v$l = \$$n\{\$k$l\}; print "$t"; }}];
  $r = qq["; $r print "] if $l;
  return $r;
}
sub _extract_array{
  my($n,$t,$l) = @_;
  my $r = qq[{ my(\$c$l,\$n$l) = (scalar(\@$n),'$n'); for(my \$i=0;\$i<\@$n;\$i++){ \$_ = \$$n\x5b\$i\x5d; print "$t"; }}];
  $r = qq["; $r print "] if $l;
  return $r;
}
sub _extract_bool{
  my($x,$t,$l) = @_;
  my $r = qq[{ if($x){ print "$t"; }}];
  $r =~ s/\<\!(\([^\)]+?\)|[^\>]+)\>/"; } elsif($1) { print "/gos;
  $r =~ s/\<\!\>/"; } else { print "/gos;
  $r = qq["; $r print "] if $l;
  return $r;
}
sub _extract_bool_unless{
  my($x,$t,$l) = @_;
  my $r = qq[{ unless($x){ print "$t"; }}];
  $r =~ s/\<\!(\([^\)]+?\)|[^\>]+)\>/"; } elsif($1) { print "/gos;
  $r =~ s/\<\!\>/"; } else { print "/gos;
  $r = qq["; $r print "] if $l;
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
      $o .= _coloring("<$r\@$2>$t</\@>",'c0c') if ! $l && $f % 2;
      $t = _extract_tags(\$t,$f,1) if $t =~ /\<\\?[\=\!\@\%]/s;
      $o .= _extract_array($n,$t,$l++); $l--;
    } elsif($t =~ s/\<\/\=\>$// && $t =~ s/^\<\=(\([^\)]+?\)|[^\>]+)\>//){
      my $x = $1;
      $o .= _coloring("<=$x>$t</=>",'00c') if ! $l && $f % 2;
      $t = _extract_tags(\$t,$f,1) if $t =~ /\<\\?[\=\!\@\%]/s;
      $o .= _extract_bool($x,$t,$l++); $l--;
    } elsif($t =~ s/\<\/\!\>$// && $t =~ s/^\<\!(\([^\)]+?\)|[^\>]+)\>//){
      my $x = $1;
      $o .= _coloring("<!$x>$t</!>",'00c') if ! $l && $f % 2;
      $t = _extract_tags(\$t,$f,1) if $t =~ /\<\\?[\=\!\@\%]/s;
      $o .= _extract_bool_unless($x,$t,$l++); $l--;
    } else{
      # output HTML code in debug
      #$o .= _coloring($t,'999') if ! $l && $f % 2;
      $o .= $l ? $t : qq[print "$t";];
    }
  }
  return $o;
}
sub _init{
  my($i,$f,$u,@o) = (ref $_[0] ? ${$_[0]} : $_[0],$_[1],$_[2]);
  if($i =~ s/^\#\![^\r\n]+([\r\n\s]+)//os){
    push(@o,$1);
  }
  foreach my $t(split(/(\<\$.+?\$\>|\<\:.+?\:\>)/s,$i)){
    if($t =~ s/^\<\$// && $t =~ s/\$\>$//){
      push(@o,_coloring($t)) if $f % 2;
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
  $CTTYPE = ref($_[0]) eq $PKGNAM ? $_[1] : $_[0];
}
sub flush{
  print $STDBAK (@HEADER ? join("\r\n",@HEADER)."\r\n":'')."Content-Type: $CTTYPE\r\n\r\n";
}
sub print{
  shift if ref $_[0] eq $PKGNAM; CORE::print @_;
}
sub echo{
  shift if ref $_[0] eq $PKGNAM; CORE::print @_;
}
sub printf{
  shift if ref $_[0] eq $PKGNAM; CORE::printf @_;
}

sub _run{
  my($ep,$ev) = (shift,shift); return eval shift;
}

sub main{
  my $ref = bless {},$PKGNAM;
  my $flg = 0;
  my $ubf = 0;
  my($pos,$now) = (1,0);
  my $htm = '';
  my $isw = (exists $ENV{DOCUMENT_ROOT})? 1 : 0;
  my $prg = shift @_;
  for(my $i=0;$i<@_;$i++){
    if($_[$i] =~ /^[\-\/]([cexu]+)$/){
      my $opt = $1;
      $flg |= 4 if $opt =~ /c/;
      $flg |= 2 if $opt =~ /x/;
      $flg |= 1 if $opt =~ /e/;
      $ubf |= 1 if $opt =~ /u/;
    } elsif($_[$i] =~ /^(\-\-?|\/)([hvV]|help|version)$/){
      print STDOUT "Content-Type: text/plain\r\n\r\n" if $isw;
      print STDOUT "twepl [OPTION(and FEATURE)S] files...\n\n  [OPTIONS]\n    -e    example-mode: output coloring source code.\n    -x    every-execute-mode: every tag every execute.\n    -c    compile-mode: output pre-compiled code.\n\n  [FEATURES]\n    -u    template-mode: use variable extractor.\n\nCopyright (C)2010 TWINKLE COMPUTING All rights reserved.\n\nReporting bugs to <twinkle\@cpan.org>\n\n";
      exit;
    } elsif($_[$i] =~ /^[\-\/]t[\=\:]?([0-9]+)$/){
      $TIMEOUT = int($1);
    #} elsif($_[$i] =~ /^\-o$/ && $i < @_){
    #  next unless open OUT,'>'.$_[++$i];
    #  $STDBAK = *OUT;
    } elsif(-f $_[$i]){
      open HTM,$_[$i];
      read HTM,$htm,(-s HTM);
      close HTM;
    }
  }
  unless($htm){
    print STDERR "twepl: no input files.\n";
    exit;
  }
  my @src = _init($htm,$flg,$ubf);
  my $tmp = '';
  my $var = bless {},$PKGNAM.'::Vars';
  open TMP,'>>',\$tmp;
  *STDOUT = *TMP;
  local $SIG{ALRM} = sub{ die 'Forced exiting, detected loop'; };
  alarm $TIMEOUT;
  if($flg > 3){
    $ref->content_type('text/plain');
    $tmp .= qq[\x23!$prg\n\n];
    if($flg > 5){
      foreach my $ept(@src){
        $tmp .= '<:'.$ept.':>';
      }
    } else{
      $tmp .= '<:'.join('',@src).':>';
    }
    $tmp .= "\n";
  } elsif($flg > 1){
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
  } else{
    if(!_run($ref,$var,join('',@src)) && $@){
      $@ =~ s/at\x20\(eval\x20[0-9]+\)\x20line\x20([0-9]+)/at line $1/go;
      $@ =~ s/\x22/\&quot\;/g; chop $@;
      $tmp = qq[<h3 style="color:#600;font-weight:bold;">Encountered 500 Internal Server Error</h3>\n\n];
      $tmp .= qq[<blockquote style="padding:4px;color:#c00;background-color:#fdd;border:solid 1px #f99;font-size:80%;">$@</blockquote>\n];
      $tmp .= qq[<hr style="border-style:solid;border-width:1px 0px 0px 0px;border-color:#900;" />\n];
      $tmp .= qq[<div style="color:#600;text-align:right;">$ENV{SERVER_SIGNATURE}</div>\n];
      $ref->header_out('Status','500 Internal Server Error');
    }
  }
  close TMP;
  *STDOUT = $STDBAK;
  &flush if $isw;
  print $STDBAK $tmp;
}

__END__
