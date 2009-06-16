use inc::Module::Install;

name     'Devel-IntelliPerl';
all_from 'lib/Devel/IntelliPerl.pm';
author   'Moritz Onken <onken@netcubed.de>';
license  'perl';

requires 'Moose' => '0.81';
requires 'PPI' => '1.203';
requires 'Path::Class';
requires 'MooseX::Method::Signatures';

build_requires 'Test::More';

repository 'http://github.com/monken/Devel-IntelliPerl/tree/master';


tests_recursive( 't' );

auto_install;


WriteAll;

