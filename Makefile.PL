use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::Textdomain',
    AUTHOR              => q{Anatoliy Lapitskiy <nuclon@cpan.org>},
    VERSION_FROM        => 'lib/Mojolicious/Plugin/Textdomain.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/Textdomain.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'Locale::TextDomain' => 0,
        'Mojolicious'        => 0,
		'Encode'             => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-Textdomain-*' },
);
