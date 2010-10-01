use Config;
use ExtUtils::Embed;

our $suf = $Config{_exe};

  open MKF,'>Makefile';
  flock MKF,2;

  print MKF "PERLPV = ppv/perlpv\n\n";

if($suf){
  my $rcc = $Config{cc} eq 'cl' ? 'rc /Fo' : 'windres -o';
  my $ldc = $Config{cc} eq 'cl' ? '' : " -o twepl$suf";
  my $cpc = $Config{cc} eq 'cl' ? 'copy' : 'cp -f';
  my $cpo = $Config{cc} eq 'cl' ? ' /B /Y' : '';
  my $rmc = $Config{cc} eq 'cl' ? 'del' : 'rm -f';
  my $rmo = $Config{cc} eq 'cl' ? ' /Q' : '';
  my $ldo = ExtUtils::Embed::ldopts;

print MKF <<_EOM_;
all: twepl$Config{_o} twres$Config{_o} twepl$suf

twres$Config{_o}: twres.rc
	$rcc twres$Config{_o} twres.rc
twepl$Config{_o}: twepl.pl
	$Config{perlpath} \$(PERLPV) -o twepl$Config{_o} twepl.pl
twepl$suf: twepl$Config{_o}
	$Config{ld} $Config{optimize}$ldc twepl$Config{_o} twres$Config{_o} $ldo
test:
	$Config{perlpath} t/EmbeddedPerl.t
install: all
	$cpc$cpo twepl$suf $Config{installbin}\\twepl$suf
uninstall:
	$rmc $Config{installbin}\\twepl$suf
clean:
	$rmc twepl$suf
	$rmc$rmo *$Config{_o}
	$rmc$rmo *.pdb
realclean: clean
	$rmc Makefile
_EOM_

} else{

print MKF <<_EOM_;
all: twepl

twepl: twepl.pl
	$Config{perlpath} \$(PERLPV) -o twepl twepl.pl
test:
	$Config{perlpath} t/EmbeddedPerl.t
install: all
	cp -f twepl $Config{installbin}/twepl
uninstall:
	rm -f $Config{installbin}/twepl
clean:
	rm -f twepl
realclean: clean
	rm -f Makefile
_EOM_

}

  close MKF;

print "Writing Makefile for EmbeddedPerl BETA.\n";
