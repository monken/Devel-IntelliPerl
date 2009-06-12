package Devel::IntelliPerl;

our $VERSION = '0.01';

use Moose;
use Moose::Util::TypeConstraints;
use PPI;
use Class::MOP;
use Path::Class;
use List::Util qw(first);

my $KEYWORD = '[a-zA-Z_][_a-zA-Z0-9]*';
my $CLASS   = '(' . $KEYWORD . ')(::' . $KEYWORD . ')*';
my $VAR     = '\$' . $CLASS;


has line_number   => ( isa => 'Int', is => 'rw', required => 1 );
has column => ( isa => 'Int', is => 'rw', required => 1 );
has filename => ( isa => 'Str', is => 'rw' );
has source => ( isa => 'Str', is => 'rw', required => 1 );
has inc => ( isa => 'ArrayRef[Str]', is => 'rw' );
has ppi => ( isa => 'PPI::Document', is => 'rw', lazy => 1, builder => '_build_ppi', clearer => 'clear_ppi' );
has error => (isa => 'Str', is => 'rw' );


after source => sub {
    my $self = shift;
    $self->clear_ppi if(@_);
};

after filename => sub {
    my $self   = shift;
    my $parent = $self->filename;
    my @libs;
    while ( $parent = $parent->parent ) {
        last if ( $parent eq $parent->parent );
        push( @libs, $parent->subdir('lib')->stringify )
          if ( -e $parent->subdir('lib') );
    }
    $self->inc( \@libs );
    unshift( @INC, @libs );
};

sub line {
    my ($self, $line) = @_;
    my @source = split("\n", $self->source);
    if(defined $line) {
        $source[$self->line_number - 1] = $line;
        $self->source(join("\n", @source));
    }
    return $source[$self->line_number - 1]; 
}

sub inject_statement {
    my ( $self, $statement ) = @_;
    my $line   = $self->line;
    my $prefix = substr( $line, 0, $self->column );
    $self->line($prefix
      . $statement
      . substr( $self->line, $self->column ));
    return $self->line;
}

sub _build_ppi {
    return PPI::Document->new(\(shift->source));
}

sub keyword {
    my ($self) = @_;
    my $line = substr( $self->line, 0, $self->column );
    if($line =~ /.*?(\$?$CLASS)->($KEYWORD)?$/) {
        return $1 || '';
    }
}

sub prefix {
    my ($self) = @_;
    my $line = substr( $self->line, 0, $self->column );
    if($line =~ /.*?(\$?$CLASS)->($KEYWORD)?$/) {
        return $4 || '';
    }
}


sub handle_self {
    my ($self) = @_;
    $self->inject_statement('; my $FINDME;');
    
    my $doc = $self->ppi;
    my $package = $doc->find_first('Statement::Package');
    my $class = $package->namespace;
    
    my $var = $doc->find('Statement::Variable');
    my $statement = first { first { $_ eq '$FINDME' } $_->variables } @{$var};

    $statement->sprevious_sibling->remove;
    $statement->remove;
    eval("$doc");
    if($@) {
        $self->error($@);
        return undef;
    }
    return $class;
}

sub handle_variable {
    my ($self) = @_;
    my $keyword = $self->keyword;
    my @source = split("\n", $self->source);
    my @previous = reverse splice(@source, 0, $self->line_number - 1 );
    my $class = undef;
    foreach my $line (@previous) {
        if ( $line =~ /\Q$keyword\E.*?($CLASS)->new/ ) {
            $class = $1; last;
        }
        elsif ( $line =~ /\Q$keyword\E.*?new ($CLASS)/ ) {
            $class = $1; last;
        }
        elsif ( $line =~ /#.*\Q$keyword\E isa ($CLASS)/ ) {
            $class = $1; last;
        }
    }
    return $class;
}

sub handle_class {}

sub trimmed_methods {}

sub methods {
    my ($self) = @_;
    my $keyword = $self->keyword;
    my $class;
    if($keyword =~ /\$self/) {
        $class = $self->handle_self;
    } elsif ( $keyword =~ /$VAR/ ) {
        $class = $self->handle_variable;
    } else {
        $class = $keyword;
    }
    
    return undef unless($class && $class =~ /^$CLASS$/);

    eval { Class::MOP::load_class($class); };
    if($@) { 
        $self->error($@);
        return undef;
    } 
    
    my $prefix = $self->prefix;
    
    my $meta = Class::MOP::Class->initialize($class);

    my @methods =
      sort { $a =~ /^_/ cmp $b =~ /^_/ } 
      sort { $a =~ /^[A-Z][A-Z]$KEYWORD/ cmp $b =~ /^[A-Z][A-Z]$KEYWORD/ }
      sort { lc($a) cmp lc($b) } $meta->get_all_method_names;
      
    return grep { $_ =~ /^$prefix/ } @methods;
}

__PACKAGE__->meta->make_immutable;

42;

__END__

=head1 NAME

Devel::IntelliPerl - Auto-completion for Perl


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Devel::IntelliPerl;

    my $foo = Devel::IntelliPerl->new();
    ...

=head1 ATTRIBUTES

=head2 line

B<Required>

Line number of the cursor. Starts at C<1>.

=head2 column

B<Required>

Position of the cursor. Starts at C<0>.

=head2 source

B<Required>

Source code.

=head2 filename

B<Optional>

Store the filename of the current file. This optional. If this value is set C<@INC> is extended by all C<lib> directories,
found in any parent directory. This is useful if you want to have access to modules which are not in C<@INC> but in
your local C<lib> folder. This method sets L</inc>.

=head2 inc

B<Optional>

All directories specified will be added to C<@INC>.

=head1 AUTHOR

Moritz Onken, C<< <onken at netcubed.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-intelliperl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-IntelliPerl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::IntelliPerl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-IntelliPerl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-IntelliPerl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-IntelliPerl>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-IntelliPerl/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
