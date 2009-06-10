use inc::Module::Install;

name     'Devel-IntelliPerl';
all_from 'lib/Devel/IntelliPerl.pm';
author   'Moritz Onken <onken@netcubed.de>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

