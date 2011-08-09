use strict;use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Calendar::Persian',
    AUTHOR        => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM  => 'lib/Calendar/Persian.pm',
    ABSTRACT_FROM => 'lib/Calendar/Persian.pm',
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Calendar-Persian-*' },
    PREREQ_PM     => {
        'Test::More'      => 0,
        'Readonly'        => '1.03',
        'Time::localtime' => '1.02',
        'List::Util'      => '1.21',
        'Date::Calc'      => '5.7',
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
);