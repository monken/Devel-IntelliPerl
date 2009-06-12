use inc::Module::Install;

name     'Devel-IntelliPerl';
all_from 'lib/Devel/IntelliPerl.pm';
author   'Moritz Onken <onken@netcubed.de>';
license  'perl';

requires 'Moose';
requires 'PPI';
requires 'Path::Class';

build_requires 'Test::More';

repository 'http://github.com/monken/Devel-IntelliPerl/tree/master';


tests_recursive( 't' );

auto_install;


WriteAll;

