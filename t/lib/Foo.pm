package Foo;
use Moose;

has bar => ( isa => 'Bar', is => 'rw' );
has foo => ( isa => 'Foo', is => 'rw' );
has signatures => ( isa => 'Signatures', is => 'rw');

1;