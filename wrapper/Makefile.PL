use Config;

my $rmc = $Config{cc} eq 'cl' ? 'del' : 'rm -f';

  open MKF,'>Makefile';
  flock MKF,2;

print MKF <<_EOM_;
MKWRAP = mkw/mkwrap

all: mkwrap

mkwrap:
	$Config{perlpath} \$(MKWRAP) -o wrapper.pl
test:
clean:
	$rmc wrapper.pl
realclean: clean
	$rmc Makefile
_EOM_

  close MKF;

print "Writing Makefile for CGI Wrapper.\n";
