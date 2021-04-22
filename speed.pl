#!/usr/bin/perl -w

sub do_quit {
    my ($in_ref, $addr) = @_;
    my @in = @$in_ref;
    my @ret;
    if ($addr =~ /^\s*\/.+\/\s*$/) {
        # address is a regex
        $addr =~ s/\s*\/(.+)\/\s*$/$1/;
        foreach my $line (@in) {
            push @ret, $line;
            last if $line =~ /$addr/;
        }
    } elsif ($addr =~ /^\s*[0-9]*[1-9][0-9]*\s*$/) {
        # address is a number
        for my $i (0 .. $#in) {
            push @ret, $in[$i];
            last if $i == $addr - 1;
        }
    } elsif ($addr =~ /^\s*$/) {
        # address is not given
        push @ret, $in[0] if defined $in[0];
    } else {
        # address is invalid
        die "$0: command line: invalid command\n"
    }
    @ret;
}

sub do_print {
    my ($in_ref, $addr) = @_;
    my @in = @$in_ref;
    my @ret;
    if ($addr =~ /^\s*\/.+\/\s*$/) {
        # address is a regex
        $addr =~ s/\s*\/(.+)\/\s*$/$1/;
        foreach my $line (@in) {
            push @ret, $line;
            push @ret, $line if $line =~ /$addr/;
        }
    } elsif ($addr =~ /^\s*[0-9]*[1-9][0-9]*\s*$/) {
        # address is a number
        for my $i (0 .. $#in) {
            push @ret, $in[$i];
            push @ret, $in[$i] if $i == $addr - 1;
        }
    } elsif ($addr =~ /^\s*$/) {
        # address is not given
        foreach my $line (@in) {
            push @ret, ($line, $line);
        }
    } else {
        # address is invalid
        die "$0: command line: invalid command\n"
    }
    @ret;
}

sub do_delete {
    my ($in_ref, $addr) = @_;
    my @in = @$in_ref;
    my @ret;
    if ($addr =~ /^\s*\/.+\/\s*$/) {
        # address is a regex
        $addr =~ s/\s*\/(.+)\/\s*$/$1/;
        foreach my $line (@in) {
            push @ret, $line if $line !~ /$addr/;
        }
    } elsif ($addr =~ /^\s*[0-9]*[1-9][0-9]*\s*$/) {
        # address is a number
        for my $i (0 .. $#in) {
            push @ret, $in[$i] if $i != $addr - 1;
        }
    } elsif ($addr =~ /^\s*$/) {
        # address is not given
        # delete every line
    } else {
        # address is invalid
        die "$0: command line: invalid command\n"
    }
    @ret;
}

# sub do_substitute {
#     my ($in_ref, $addr) = @_;
#     my @in = @$in_ref;
#     my @ret;
#     if ($addr =~ /^\s*\/.+\/\s*$/) {
#         # address is a regex
#         $addr =~ s/\s*\/(.+)\/\s*$/$1/;
#         foreach my $line (@in) {
#             push @ret, $line if $line !~ /$addr/;
#         }
#     } elsif ($addr =~ /^\s*[0-9]*[1-9][0-9]*\s*$/) {
#         # address is a number
#         for my $i (0 .. $#in) {
#             push @ret, $in[$i] if $i != $addr - 1;
#         }
#     } elsif ($addr =~ /^\s*$/) {
#         # address is not given
#         # delete every line
#     } else {
#         # address is invalid
#         die "$0: command line: invalid command\n"
#     }
#     @ret;
# }

# die unless @ARGV == 1;
# my @in = <STDIN>;
