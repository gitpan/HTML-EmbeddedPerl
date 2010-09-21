use Config;

our $suf = $^O =~ /win/ ? '.exe' : '';

  open MKF,'>Makefile';
  flock MKF,2;

print MKF <<_EOM_;
PERLPV = ppv/perlpv

all: twepl$suf

twepl$suf: twepl.pl
	$Config{perlpath} \$(PERLPV) twepl.pl
	strip twepl$suf
test:
	$Config{perlpath} t/EmbeddedPerl.t
install: all
	cp -f twepl$suf $Config{installbin}/twepl$suf
uninstall:
	rm -f $Config{installbin}/twepl$suf
clean:
	rm -f twepl$suf
realclean: clean
	rm -f Makefile
_EOM_

  close MKF;

print "Writing Makefile for EmbeddedPerl BETA.\n";
