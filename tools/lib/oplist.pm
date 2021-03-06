package oplist;
use strict;
use warnings;
use File::Spec::Functions qw(splitpath updir catpath catdir);
use constant OPLIST => do {
    my ($path, $directory, $filename) = splitpath(__FILE__);
    catpath($path, catdir($directory, (updir()) x 2, qw(src core)), 'oplist');
};

# Parse MoarVM oplist file and stash it in @OPLIST and %OPLIST
sub parse_oplist {
    my ($fh) = @_;
    my @oplist;
    while (<$fh>) {
        # remove comments and skip empty strings
        chomp and s/#.*$//;
        next unless length;
        my ($name, @meta) = split /\s+/;
        my ($attribute, @operands, @adverbs);
        for (@meta) {
            if (m/^[-+.:*]\w$/) {
                $attribute = $_;
            } elsif (m/^:\w+$/) {
                push @adverbs, $_;
            } elsif (m/^([rw])l?\((.+)\)$/) {
                push @operands, $1 => $2;
            } else {
                push @operands, '' => $_;
            }
        }
        push @oplist, [ $name, $attribute, \@operands, \@adverbs ];
    }
    return @oplist;
}

sub import {
    my ($class, $file) = (@_, OPLIST);
    open my $fh, '<', $file or die $!;
    my @oplist = parse_oplist($fh);
    my %oplist = map {
        $_->[0] => { attr => $_->[1], operands => $_->[2], adverbs => $_->[3] }
    } @oplist;
    my ($caller) = caller();
    {
        no strict 'refs';
        *{$caller . '::OPLIST'} = \@oplist;
        *{$caller . '::OPLIST'} = \%oplist;
    }
    close $fh;
}

1;
