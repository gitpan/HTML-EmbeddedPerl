#!/usr/bin/perl
package twepl;
use strict;
use warnings;
our $VERSION = '0.06';
our $TIMEOUT = 2;
local $SIG{ALRM} = sub{ die 'Force exiting, detected loop'; };
my $STDBAK = *STDOUT;
sub header_out{ $_[0]->{h} .= "$_[1]: $_[2]\r\n"; }
sub content_type{ $_[0]->{t} = $_[1]; }
sub flush{ print $STDBAK "$_[0]->{h}Content-Type: $_[0]->{t}\r\n\r\n"; }
sub print{ shift; CORE::print @_; }
sub run{ my($epl,$var) = (shift,shift); return eval shift; }
my $var = bless {},__PACKAGE__.'::Vars';
my $ref = bless {};
$ref->{t} = 'text/html';
my $src = $ref->{h} = '';
exit unless open S,@ARGV ? shift @ARGV : exit;
sysread S,$src,(-s S);
close S;
my($pos,$now,$tmp) = (-1,0,'');
$src =~ s/^\#[^\r\n]+//;
$pos += $src  =~ s/^\r\n|^[\r\n]//gs;
open TMP,'>>',\$tmp;
*STDOUT = *TMP;
alarm $TIMEOUT;
foreach my $tag(split(/(\<\$.+?)\$\>/s,$src)){
$now = $pos;
$pos += $tag =~ s/\r\n|\r|\n/\n/gs;
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
}; close TMP; *STDOUT = $STDBAK; flush $ref; print $tmp;
