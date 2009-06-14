package Devel::IntelliPerl::Editor::TextMate;

use Moose;

use Exporter qw(import);
use Devel::IntelliPerl;
use Text::Table;

extends 'Devel::IntelliPerl::Editor';

our @EXPORT = qw(run);

has editor => ( isa => 'Str', is => 'ro', default => 'TextMate' );

sub run {
    my ($self) = @_;
    my @source;
    my ( $line_number, $column, $filename ) = @ARGV;
    push( @source, $_ ) while (<STDIN>);
    my $ip = Devel::IntelliPerl->new(
        line_number => $line_number,
        column      => $column + 1,
        source      => join( '', @source ),
        filename => $filename
    );
    my @methods = $ip->methods;
    if ( @methods > 1 ) {
        my $rows = 40;
        my $tb   = Text::Table->new;
        my @data;
        for ( my $i = 0 ; $i < $rows ; $i++ ) {
            my @arr;
            for ( my $k = 0 ; $k < @methods ; $k++ ) {
                push( @arr, $methods[$k] ) if ( $k % $rows == $i );
            }
            push( @data, \@arr );

        }
        $tb->load(@data);
        print $tb;
    }
    elsif (my $method = shift @methods) {
        print substr( $method, length $ip->prefix );
    } elsif (my $error = $ip->error) {
        print "The following error occured:\n".$error;
    }
    return;

}

__PACKAGE__->meta->make_immutable;


=head1 NAME

Devel::IntelliPerl::Editor::TextMate - IntelliPerl integration for TextMate

=head1 SYNOPSIS

    out=`perl -MDevel::IntelliPerl::Editor::TextMate -e 'run' $TM_LINE_NUMBER $TM_LINE_INDEX "$TM_FILEPATH" 2>/dev/null`
    lines=`echo "$out" | wc -l`;
    if (($lines > 1)); then
      exit_show_tool_tip "$out"
    else
      exit_insert_text "$out"
    fi

Create a new Command in the Bundle Editor and paste this bash script. Set "Input" to "Entire Document" and "Output" to "Discard".
If you set "Scope Selector" to C<source.perl> this script is run only if you are editing a perl file.

To run this command using a key set "Activation" to "Key Equivalent" and type the desired key in the box next to it.

=head1 METHODS

=head2 editor

Set to C<TextMate>.

=head2 run

This method is exported and invokes L<Devel::IntelliPerl>.

=head1 SEE ALSO

L<http://macromates.com/>, L<Devel::IntelliSense>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
