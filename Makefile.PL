use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Mojolicious::Plugin::NamespaceForm',
  ABSTRACT_FROM => 'lib/Mojolicious/Plugin/NamespaceForm.pm',
  VERSION_FROM => 'lib/Mojolicious/Plugin/NamespaceForm.pm',
  AUTHOR => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE => 'perl',
  PREREQ_PM => {
    'Mojolicious' => '3.40',
  },
  BUILD_REQUIRES => {
    'Test::More' => '0.90',
  },
  META_MERGE => {
    resources => {
      license => 'http://dev.perl.org/licenses/',
      homepage => 'https://metacpan.org/release/Mojolicious-Plugin-NamespaceForm',
      bugtracker => 'https://github.com/jhthorsen/mojolicious-plugin-namespaceform/issues',
      repository => 'https://github.com/jhthorsen/mojolicious-plugin-namespaceform.git',
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);
