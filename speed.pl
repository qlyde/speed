#!/usr/bin/perl -w
# James Kroeger (z5282841)

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
# return: a tuple with the address and instruction for that command or () for invalid commands
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
        ($addr =~ /^\s*([0-9]*[1-9][0-9]*|\/[^,]+\/|\$)\s*,\s*([0-9]*[1-9][0-9]*|\/[^,]+\/|\$)\s*$/ &&
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

# check command file exists and has valid commands (specified by -f option)
sub check_cmd_file {
    my $filename = shift;
    open my $fh, '<', $filename or no_such_file $filename;
    while (my $line = <$fh>) {
        foreach my $cmd (split /;/, $line) {
            invalid_command_file $filename, $. if check_cmd $cmd;
        }
    }
    close $fh;
}

# given: a command, instruction and a line
# execute the command on that line
# return: status to indicate how cycles should proceed
sub do_cmd {
    my ($cmd, $instr, $line_ref) = @_;

    return STATUS_LAST if $instr eq INSTR_QUIT; # quit
    print $$line_ref . "\n" if $instr eq INSTR_PRINT; # print
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
    my ($cmds_ref, $handles_ref) = @_;
    my @cmds = @$cmds_ref;
    my @handles = @$handles_ref;

    my %in_range; # one range per command

    # sed performs a cycle on each line
    my $lineno = 1; # use instead of $. for multiple files
    my $handle = (@handles == 0) ? STDIN : shift @handles; # use STDIN if no files
    while (my $line = <$handle>) {
        chomp $line;
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
                next if $lineno != $addr;
            } elsif ($addr =~ /^\s*$/) {
                # exec command on every line
            } elsif ($addr =~ /^\s*\$\s*$/) {
                # exec command on last line
                next unless eof and @handles == 0; # last line of last file
            } elsif ($addr =~ /^\s*([0-9]*[1-9][0-9]*|\/[^,]+\/|\$)\s*,\s*([0-9]*[1-9][0-9]*|\/[^,]+\/|\$)\s*$/) {
                my ($start, $end) = ($1, $2);

                # check for start
                my $is_start = 0;
                if ($start =~ /^\s*\/[^,]+\/\s*$/) {
                    my $start_regex = $start =~ s/^\s*\/([^,]+)\/\s*$/$1/r;
                    $is_start = 1 if $line =~ /$start_regex/;
                } elsif ($start =~ /^\s*[0-9]*[1-9][0-9]*\s*$/) {
                    $is_start = 1 if $lineno == $start;
                }

                # check for end
                my $is_end = 0;
                my $past_end = 0; # for if start matches, end is a number and we are past that line
                if ($end =~ /^\s*\/[^,]+\/\s*$/) {
                    my $end_regex = $end =~ s/^\s*\/([^,]+)\/\s*$/$1/r;
                    $is_end = 1 if $line =~ /$end_regex/;
                } elsif ($end =~ /^\s*[0-9]*[1-9][0-9]*\s*$/) {
                    $is_end = 1 if $lineno >= $end;
                    $past_end = 1 if $lineno > $end;
                }

                # check if in range
                my $end_flag = 0; # so we can exec cmd on last line in inclusive range
                if ($is_start && !$in_range{$i} && $past_end) {
                    $end_flag = 1; # don't begin the range since we are past the line
                } elsif ($is_start && !$in_range{$i}) {
                    $in_range{$i} = 1;
                } elsif ($is_end && $in_range{$i} && $end !~ /^\s*\$\s*$/) { # never end range if end is $
                    $in_range{$i} = 0;
                    $end_flag = 1;
                }

                # check if in between
                if ($start =~ /^\s*[0-9]*[1-9][0-9]*\s*$/ && $end =~ /^\s*[0-9]*[1-9][0-9]*\s*$/) {
                    my $is_between = ($start <= $lineno && $lineno <= $end) ? 1 : 0;
                    $is_between = 1 if $end <= $start && $start == $lineno; # edge case
                    $in_range{$i} = $is_between;
                    $end_flag = 0 if !$is_between;
                }

                # check if start is $
                if ($start =~ /^\s*\$\s*$/) {
                    # only exec cmd if last line no matter what end is
                    $end_flag = 0;
                    $in_range{$i} = (eof and @handles == 0) ? 1 : 0;
                }

                next unless $in_range{$i} or $end_flag;
            }

            # execute command
            $status = do_cmd $cmd, $instr, \$line; # so line can be modified
            last if $status eq STATUS_NEXT or $status eq STATUS_LAST;
        }

        $lineno++;
        $handle = shift @handles if @handles != 0 && eof; # go to next file

        next if $status eq STATUS_NEXT; # delete starts next cycle immediately
        print $line . "\n" unless exists $OPTS{n}; # print line unless option -n
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
    check_cmd_file $OPTS{f};
    open my $fh, '<', $OPTS{f} or no_such_file $OPTS{f};
    my $arg = do { local $/; <$fh> }; # read whole file as a single string
    $arg =~ s/#[^\n]*//g; # remove comments
    @cmds = split /;|\n/, $arg;
    close $fh;
} else {
    $ARGV[0] =~ s/#[^\n]*//g; # remove comments
    @cmds = split /;|\n/, $ARGV[0];
}

# check cmdline commands
check_cmd_cmdline @cmds if !exists $OPTS{f};

# get files if they are given
shift @ARGV if !exists $OPTS{f}; # get rid of the script
my @handles;
foreach my $file (@ARGV) {
    error if ! -f $file;
    open my $fh, '<', $file or die;
    push @handles, $fh;
}

# do speed
sed \@cmds, \@handles; # pass in input files

# close files
foreach my $handle (@handles) {
    close $handle;
}
