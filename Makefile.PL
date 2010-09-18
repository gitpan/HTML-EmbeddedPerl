use ExtUtils::MakeMaker;
WriteMakefile(
  NAME         => 'HTML::EmbeddedPerl',
  AUTHOR       => 'Twinkle Computing <twinkle@cpan.org>',
  VERSION_FROM => 'lib/HTML/EmbeddedPerl.pm',
  EXE_FILES    => ['bin/twepl'],
  MAN1PODS     => {'pod/en/twepl.pod'=>'blib/man1/twepl.1'},
);
