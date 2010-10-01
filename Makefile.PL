use Config;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'HTML::EmbeddedPerl',
  ABSTRACT_FROM => 'lib/HTML/EmbeddedPerl.pm',
  AUTHOR        => 'Twinkle Computing <twinkle@cpan.org>',
  LICENSE       => 'perl',
  VERSION_FROM  => 'lib/HTML/EmbeddedPerl.pm',
  INST_SCRIPT   => 'blib/bin',
  EXE_FILES     => ["bin/twepl$Config{_exe}"],
  MAN1PODS      => {'pod/twepl.pod'=>'blib/man1/twepl.1'},
);
