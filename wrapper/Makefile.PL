use Config;

open MKF,'>Makefile';
flock MKF,2;
print MKF <<_EOM_;
MKWRAP = Makefile.PL

all:
test:
clean:
	rm -f twrap
realclean: clean
	rm -f Makefile
_EOM_
close MKF;

print "Writing Makefile for CGI Wrapper.\n";

open WRAPPER,'>twrap';
flock WRAPPER,2;
print WRAPPER <<_EOW_;
#!$Config{perlpath}

use HTML::EmbeddedPerl;

sub abort{
  my \$msg = shift;
  print STDOUT "Content-Type: text/plain\\r\\n\\r\\nERROR: \$msg\\n";
  exit;
}

my \$htm;

abort 'cannot open file.' unless open HTM, "<\$ENV{PATH_TRANSLATED}";
sysread HTM,\$htm,(-s HTM);
close HTM;

abort 'empty.' unless \$htm;

ep(\\\$htm);
_EOW_
close WRAPPER;
