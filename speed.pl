#!/usr/bin/perl -w

use Getopt::Long;
use constant {
    INSTR_QUIT   => "INSTR_QUIT",
    INSTR_PRINT  => "INSTR_PRINT",
    INSTR_DELETE => "INSTR_DELETE",
    INSTR_SUBST  => "INSTR_SUBST",
    INSTR_NONE   => "INSTR_NONE",
    STATUS_NONE  => "STATUS_NONE", # cycling continues as normal
    STATUS_NEXT  => "STATUS_NEXT", # immediately go to next cycle
    STATUS_LAST  => "STATUS_LAST", # stop cycling
};

# options
my %OPTS;

sub usage {
    print STDERR "usage: $0 [-i] [-n] [-f <script-file> | <sed-command>] [<files>...]\n";
    exit 1;
}

sub invalid_command_cmdline {
    print STDERR "$0: command line: invalid command\n";
    exit 1;
}

sub invalid_command_file {
    my ($filename, $lineno) = @_;
    print STDERR "$0: file $filename line $lineno: invalid command\n";
    exit 1;
}

sub no_such_file {
    my $file = shift;
    print STDERR "$0: couldn't open file $file: $!\n";
    exit 1;
}

sub error {
    print STDERR "$0: error\n";
    exit 1;
}

# given: a command
# return: a tuple with the address and instruction for that command or undef for invalid commands
sub parse_cmd {
    my $cmd = shift;
    $cmd =~ s/#[^\n]*//g; # remove comments
    if ($cmd =~ /q\s*$/) {
        my $addr = $cmd =~ s/q\s*$//r;
        return ($addr, INSTR_QUIT);
    } elsif ($cmd =~ /p\s*$/) {
        my $addr = $cmd =~ s/p\s*$//r;
        return ($addr, INSTR_PRINT);
    } elsif ($cmd =~ /d\s*$/) {
        my $addr = $cmd =~ s/d\s*$//r;
        return ($addr, INSTR_DELETE);
    } elsif ($cmd =~ /s(.).+\1.*\1\s*g?\s*$/) {
        my $addr = $cmd =~ s/s(.).+\1.*\1\s*g?\s*$//r;
        return ($addr, INSTR_SUBST);
    } elsif ($cmd =~ /^\s*$/) {
        # empty command is valid
        return ("", INSTR_NONE);
    }
    return ();
}

# check a given cmd is valid: instruction and address must be valid
sub check_cmd {
    my $cmd = shift;
    my ($addr, $instr) = parse_cmd $cmd;
    return 1 if !defined $addr; # cmd is invalid

    # check if address is valid
    return 1 if !(
        $addr =~ /^\s*\/[^,]+\/\s*$/ || # address is a regex /.../
        $addr =~ /^\s*[0-9]*[1-9][0-9]*\s*$/ || # address is a positive integer
        $addr =~ /^\s*$/ || # address is nothing
        $addr =~ /^\s*\$\s*$/ || # address is $ (last line)
        ($addr =~ /^\s*([0-9]*[1-9][0-9]*|\/[^,]+\/)\s*,\s*([0-9]*[1-9][0-9]*|\/[^,]+\/)\s*$/ &&
            $instr ne INSTR_QUIT) # address is a range and instruction is p,d or s
    );

    return 0; # valid command
}

# check commands given via command line are valid
sub check_cmd_cmdline {
    foreach my $cmd (@_) {
        invalid_command_cmdline if check_cmd $cmd;
    }
}

# check command file has valid commands (specified by -f option)
sub check_cmd_file {
    my ($filename, $fh) = @_;
    while (my $line = <$fh>) {
        foreach my $cmd (split /;/, $line) {
            invalid_command_file $filename, $. if check_cmd $cmd;
        }
    }
}

# check input files exist
sub check_input_files {
    shift if !exists $OPTS{f}; # get rid of sed script if -f not specified
    foreach my $file (@_) {
        error if ! -f $file;
    }
}

# given: a command, instruction and a line
# execute the command on that line
# return: status to indicate how cycles should proceed
sub do_cmd {
    my ($cmd, $instr, $line_ref) = @_;

    return STATUS_LAST if $instr eq INSTR_QUIT; # quit
    print $$line_ref if $instr eq INSTR_PRINT; # print
    return STATUS_NEXT if $instr eq INSTR_DELETE; # delete: start next cycle

    # substitute: change pattern space (current line)
    if ($instr eq INSTR_SUBST) {
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

    my %in_range; # one range per command
    my %is_start_of_range;
    my %is_end_of_range;

    # sed performs a cycle on each line
    while (my $line = <STDIN>) {
        my $status = STATUS_NONE;

        # commands are executed on the line if the line matches the address
        foreach my $i (0..$#cmds) {
            my $cmd = $cmds[$i];
            my ($addr, $instr) = parse_cmd $cmd;
            if ($addr =~ /^\s*\/[^,]+\/\s*$/) {
                # addr is a regex
                $addr =~ s/^\s*\/([^,]+)\/\s*$/$1/;
                next if $line !~ /$addr/;
            } elsif ($addr =~ /^\s*[0-9]*[1-9][0-9]*\s*$/) {
                # addr is a number
                next if $. != $addr;
            } elsif ($addr =~ /^\s*$/) {
                # exec command on every line
            } elsif ($addr =~ /^\s*\$\s*$/) {
                # exec command on last line
                next unless eof;
            } elsif ($addr =~ /^\s*([0-9]*[1-9][0-9]*|\/[^,]+\/)\s*,\s*([0-9]*[1-9][0-9]*|\/[^,]+\/)\s*$/) {
                my ($start, $end) = ($1, $2);

                # check for start
                $is_start_of_range{$i} = 0;
                if ($start =~ /^\s*\/[^,]+\/\s*$/) {
                    $start =~ s/^\s*\/([^,]+)\/\s*$/$1/;
                    $in_range{$i} = $is_start_of_range{$i} = 1 if $line =~ /$start/;
                } else {
                    $in_range{$i} = $is_start_of_range{$i} = 1 if $. == $start;
                }

                # check for end
                $is_end_of_range{$i} = 0;
                if ($end =~ /^\s*\/[^,]+\/\s*$/) {
                    $end =~ s/^\s*\/([^,]+)\/\s*$/$1/;
                    if ($line =~ /$end/ && $in_range{$i}) { $in_range{$i} = 0; $is_end_of_range{$i} = 1; }
                } else {
                    if ($. >= $end && $in_range{$i}) {
                        $in_range{$i} = 0;
                        $is_end_of_range{$i} = ($. == $end) ? 1 : 0; # not end if $. > $end
                    }
                }

                # check if in range
                $in_range{$i} = 1 if $is_start_of_range{$i}; # in case start also matches end
                next unless $in_range{$i} or $is_end_of_range{$i};
            }

            # execute command
            $status = do_cmd $cmd, $instr, \$line; # so line can be modified
            last if $status eq STATUS_NEXT or $status eq STATUS_LAST;
        }

        next if $status eq STATUS_NEXT; # delete starts next cycle immediately
        print $line unless exists $OPTS{n}; # print line unless option -n
        last if $status eq STATUS_LAST; # quit: lowercase q prints THEN exits
    }
}

###############################################################################

{
    local $SIG{__WARN__} = \&usage; # suppress "Unknown option:"
    GetOptions(\%OPTS, "n", "f=s");
}
usage unless @ARGV > 0 || exists $OPTS{f};

# get cmds from file or from cmd line
my @cmds;
if (exists $OPTS{f}) {
    open my $fh, '<', $OPTS{f} or no_such_file $OPTS{f};
    check_cmd_file $OPTS{f}, $fh; # check command file has valid commands
    close $fh;

    open $fh, '<', $OPTS{f};
    my $arg = do { local $/; <$fh> }; # read whole file as a single string
    $arg =~ s/#[^\n]*//g; # remove comments
    @cmds = split /;|\n/, $arg;
    close $fh;
} else {
    $ARGV[0] =~ s/#[^\n]*//g;
    @cmds = split /;|\n/, $ARGV[0];
}

check_input_files @ARGV if (@ARGV > 1 && !exists $OPTS{f}) || (@ARGV > 0 && exists $OPTS{f});
check_cmd_cmdline @cmds if !exists $OPTS{f};

# do speed
sed \@cmds;
