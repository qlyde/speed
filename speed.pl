#!/usr/bin/perl -w

sub usage {
    die "usage: $0 [-i] [-n] [-f <script-file> | <sed-command>] [<files>...]\n";
}

sub invalid_command {
    die "$0: command line: invalid command\n"
}

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
        # quit after first line
        push @ret, $in[0] if defined $in[0];
    } else {
        # address is invalid
        invalid_command;
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
        # print every line
        foreach my $line (@in) {
            push @ret, ($line, $line);
        }
    } else {
        # address is invalid
        invalid_command;
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
        invalid_command;
    }
    @ret;
}

sub do_substitute {
    my ($in_ref, $addr, $search, $replace, $g_flag) = @_;
    my @in = @$in_ref;
    my @ret;
    if ($addr =~ /^\s*\/.+\/\s*$/) {
        # address is a regex
        $addr =~ s/\s*\/(.+)\/\s*$/$1/;
        foreach my $line (@in) {
            $line =~ s/$search/$replace/ if !defined $g_flag && $line =~ /$addr/;
            $line =~ s/$search/$replace/g if defined $g_flag && $line =~ /$addr/;
            push @ret, $line;
        }
    } elsif ($addr =~ /^\s*[0-9]*[1-9][0-9]*\s*$/) {
        # address is a number
        for my $i (0 .. $#in) {
            $in[$i] =~ s/$search/$replace/ if !defined $g_flag && $i == $addr - 1;
            $in[$i] =~ s/$search/$replace/g if defined $g_flag && $i == $addr - 1;
            push @ret, $in[$i];
        }
    } elsif ($addr =~ /^\s*$/) {
        # address is not given
        # substitute every line
        foreach my $line (@in) {
            $line =~ s/$search/$replace/ if !defined $g_flag;
            $line =~ s/$search/$replace/g if defined $g_flag;
            push @ret, $line;
        }
    } else {
        # address is invalid
        invalid_command;
    }
    @ret;
}

sub do_cmd {
    my ($cmd) = @_;
    my @in = <STDIN>;
    if ($cmd =~ /q\s*$/) {
        # quit cmd
        $cmd =~ s/q\s*$//;
        print do_quit \@in, $cmd;
    } elsif ($cmd =~ /p\s*$/) {
        # print cmd
        $cmd =~ s/p\s*$//;
        print do_print \@in, $cmd;
    } elsif ($cmd =~ /d\s*$/) {
        # delete cmd
        $cmd =~ s/d\s*$//;
        print do_delete \@in, $cmd;
    } elsif ($cmd =~ /s\/.*\/.*\/\s*g?\s*$/) {
        # substitute cmd
        my ($addr, $search, $replace) = $cmd =~ /^(.*)s\/(.*)\/(.*)\/\s*g?\s*$/;
        if ($cmd =~ /s\/.*\/.*\/\s*g\s*$/) {
            print do_substitute \@in, $addr, $search, $replace, 1; # defined g_flag
        } else {
            print do_substitute \@in, $addr, $search, $replace; # no g_flag
        }
    } else {
        # unknown command
        invalid_command;
    }
}

die unless @ARGV == 1;
do_cmd @ARGV;
