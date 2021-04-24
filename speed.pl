#!/usr/bin/perl -w

use Getopt::Long;
use constant {
    INSTR_Q     => "INSTR_Q",
    INSTR_P     => "INSTR_P",
    INSTR_D     => "INSTR_D",
    INSTR_S     => "INSTR_S",
    STATUS_NONE => "STATUS_NONE", # cycling continues as normal
    STATUS_NEXT => "STATUS_NEXT", # immediately go to next cycle
    STATUS_LAST => "STATUS_LAST", # stop cycling
};

# options
my %OPTS;

sub usage {
    print STDERR "usage: $0 [-i] [-n] [-f <script-file> | <sed-command>] [<files>...]\n";
    exit 1;
}

sub invalid_command {
    print STDERR "$0: command line: invalid command\n";
    exit 1;
}

sub no_such_file {
    my $file = shift;
    print STDERR "$0: couldn't open file $file: $!\n";
    exit 1;
}

# given: a command
# return: a tuple with the address and instruction for that command
sub parse_cmd {
    my $cmd = shift;
    if ($cmd =~ /q\s*$/) {
        my $addr = $cmd =~ s/q\s*$//r;
        ($addr, INSTR_Q);
    } elsif ($cmd =~ /p\s*$/) {
        my $addr = $cmd =~ s/p\s*$//r;
        ($addr, INSTR_P);
    } elsif ($cmd =~ /d\s*$/) {
        my $addr = $cmd =~ s/d\s*$//r;
        ($addr, INSTR_D);
    } elsif ($cmd =~ /s(.).+\1.*\1\s*g?\s*$/) {
        my $addr = $cmd =~ s/s(.).+\1.*\1\s*g?\s*$//r;
        ($addr, INSTR_S);
    } else {
        invalid_command;
    }
}

# given: a command, instruction and a line
# execute the command on that line
# return: status to indicate how cycles should proceed
sub do_cmd {
    my ($cmd, $instr, $line_ref) = @_;

    return STATUS_LAST if $instr eq INSTR_Q; # quit
    print $$line_ref if $instr eq INSTR_P; # print
    return STATUS_NEXT if $instr eq INSTR_D; # delete: start next cycle

    # substitute: change pattern space (current line)
    if ($instr eq INSTR_S) {
        my ($sep, $search, $replace) = $cmd =~ /s(.)(.+)\1(.*)\1\s*g?\s*$/;
        ($cmd =~ /s(.).+\1.*\1\s*g\s*$/) ? ($$line_ref =~ s/$search/$replace/g) : ($$line_ref =~ s/$search/$replace/);
    }

    return STATUS_NONE;
}

# given: a list of commands
# execute each command on every line of input
sub sed {
    my $cmds_ref = shift;
    my @cmds = @$cmds_ref;
    my @residual_cmds; # commands to execute after cycles

    # sed performs a cycle on each line
    my $status = STATUS_NONE;
    my $prev_line;
    while (my $line = <STDIN>) {
        if (defined $prev_line and $status ne STATUS_NEXT) { # dont print if line got deleted
            last if $status eq STATUS_LAST; # quit
            print $prev_line unless exists $OPTS{n};
        }
        $status = STATUS_NONE;

        # commands are executed on the line if the line matches the address
        foreach my $cmd (@cmds) {
            my ($addr, $instr) = parse_cmd $cmd;
            if ($addr =~ /^\s*\/.+\/\s*$/) {
                # addr is a regex
                $addr =~ s/^\s*\/(.+)\/\s*$/$1/;
                next if $line !~ /$addr/;
            } elsif ($addr =~ /^\s*[0-9]*[1-9][0-9]*\s*$/) {
                # addr is a number
                next if $. != $addr;
            } elsif ($addr =~ /^\s*$/) {
                # exec command on every line
            } elsif ($addr =~ /^\s*\$\s*$/) {
                # exec command on last line
                push @residual_cmds, $cmd if $. == 1;
                next;
            } else {
                # invalid addr
                invalid_command;
            }
            $status = do_cmd $cmd, $instr, \$line; # so line can be modified
            last if $status eq STATUS_NEXT or $status eq STATUS_LAST;
        }

        $prev_line = $line;
    }

    # process last line
    foreach my $cmd (@residual_cmds) {
        my ($addr, $instr) = parse_cmd $cmd;
        $status = do_cmd $cmd, $instr, \$prev_line;
        last if $status eq STATUS_NEXT or $status eq STATUS_LAST;
    }
    print $prev_line if !exists $OPTS{n} && defined $prev_line && $status ne STATUS_NEXT;
}

{
    local $SIG{__WARN__} = \&usage; # suppress "Unknown option:"
    GetOptions(\%OPTS, "n", "f=s");
}
usage unless @ARGV > 0 || exists $OPTS{f};

# get cmds from file or from cmd line
my @cmds;
if (exists $OPTS{f}) {
    open my $fh, '<', $OPTS{f} or no_such_file $OPTS{f};
    @cmds = split /;|\n/, do { local $/; <$fh> };
    close $fh;
} else {
    @cmds = split /;|\n/, $ARGV[0];
}

# do speed
sed \@cmds;
