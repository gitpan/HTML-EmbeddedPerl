use Config;
use ExtUtils::Embed;

my $optsf = $Config{_exe};
my $optop = $Config{optimize};
my $optcc = ExtUtils::Embed::ccopts;
my $optld = ExtUtils::Embed::ldopts;
my $optip = '-I .. -I ../mod_twepl';

if($^O =~ /cygwin/i){
  $optcc =~ s/\-fstack\-protector//g;
  $optld =~ s/\-fstack\-protector//g;
}

  open MKF, '>Makefile';
  flock MKF, 2;

if($suf){
  my $rcc = $Config{cc} eq 'cl' ? 'rc /Fo' : 'windres -o';
  my $ldc = $Config{cc} eq 'cl' ? '' : " -o twepl$suf";
  my $cpc = $Config{cc} eq 'cl' ? 'copy' : 'cp -f';
  my $cpo = $Config{cc} eq 'cl' ? ' /B /Y' : '';
  my $rmc = $Config{cc} eq 'cl' ? 'del' : 'rm -f';
  my $rmo = $Config{cc} eq 'cl' ? ' /Q' : '';

print MKF <<_EOM_;
all: twres$Config{_o} twepl$suf

twres$Config{_o}: twres.rc
	$rcc twres$Config{_o} twres.rc
twepl$suf: twepl$Config{_o}
	$Config{ld} $Config{optimize}$ldc twepl.c twres$Config{_o} $optip $optld
test:
	./twepl$suf t/twepx.t
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

twepl:
	$Config{cc} $optop -o twepl twepl.c $optcc $optip $optld
test:
	./twepl t/twepx.t
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

print "Writing Makefile for twepl.\n";
