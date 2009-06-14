
use MooseX::Declare;
use Moose::Util::TypeConstraints;

BEGIN { subtype 'PathClassFile', as 'Path::Class::File'; }

class Declare {

    method file (PathClassFile $foo) returns (PathClassFile) {
        return new Path::Class::File;
    }

}

1;