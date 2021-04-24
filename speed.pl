#!/usr/bin/perl -w

use constant {
    INSTR_Q => "INSTR_Q",
    INSTR_P => "INSTR_P",
    INSTR_D => "INSTR_D",
    INSTR_S => "INSTR_S",
    STATUS_NONE => "STATUS_NONE", # cycling continues as normal
    STATUS_NEXT => "STATUS_NEXT", # immediately go to next cycle
    STATUS_LAST => "STATUS_LAST"  # stop cycling
};

sub usage {
    die "usage: $0 [-i] [-n] [-f <script-file> | <sed-command>] [<files>...]\n";
}

sub invalid_command {
    die "$0: command line: invalid command\n";
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

# given: a list of lines and a list of commands
# execute each command on every line
sub sed {
    my ($lines_ref, $cmds_ref) = @_;

    my @lines = @$lines_ref;
    my @cmds = @$cmds_ref;

    # sed performs a cycle on each line
    foreach my $i (0..$#lines) {
        my $line = $lines[$i];
        my $status = STATUS_NONE;

        # commands are executed on the line if the line matches the address
        foreach my $cmd (@cmds) {
            my ($addr, $instr) = parse_cmd $cmd;
            if ($addr =~ /^\s*\/.+\/\s*$/) {
                # addr is a regex
                $addr =~ s/^\s*\/(.+)\/\s*$/$1/;
                next if $line !~ /$addr/;
            } elsif ($addr =~ /^\s*[0-9]*[1-9][0-9]*\s*$/) {
                # addr is a number
                next if $i != $addr - 1;
            } elsif ($addr =~ /^\s*$/) {
                # exec command on every line
            } else {
                # invalid addr
                invalid_command;
            }
            $status = do_cmd $cmd, $instr, \$line; # so line can be modified
            last if $status eq STATUS_NEXT or $status eq STATUS_LAST;
        }

        next if $status eq STATUS_NEXT; # delete starts next cycle immediately
        print $line unless exists $FLAGS{"-n"}; # print line unless option -n
        last if $status eq STATUS_LAST; # quit: lowercase q prints THEN exits
    }
}

# sub parse_args {
#     my @args = @_;
#     my %flags;
#     foreach my $arg (@args) {
#         if ($arg eq "-n") {
#             $flags{"-n"} = 1;
#         } elsif () {
#             usage;
#         }
#     }
# }

usage if @ARGV == 0;
my @lines = <STDIN>;
my @cmds = split /;/, $ARGV[0];
sed \@lines, \@cmds;
