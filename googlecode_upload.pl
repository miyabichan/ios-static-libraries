#!/usr/bin/perl

###############################################################################
# A script to upload files to googlecode
#
# Requires curl binary (http://curl.haxx.se/) compiled with https. 
#
# muquit@muquit.com Sep-08-2007 - first cut
#
###############################################################################

use strict;
use Getopt::Long;
$|=1;

## --- globals.  -starts-
my $me=$0;
$me =~ s!.*/!!;

my $g_version_s="1.01";
my $g_debug=0;
my $g_help=0;
my $g_version=0;
my $g_show_progress=0;
my $g_quiet=0;
my ($g_project,$g_os,$g_user,$g_pass,$g_summary,$g_labels,$g_file)='';
my $g_curl_path="curl";
my $g_domain="googlecode.com";
my $g_loc="/files";
$SIG{INT}=\&catch_intr;

my %g_options=(
    "file=s"    =>\$g_file,
    "project=s" =>\$g_project,
    "progress"  =>\$g_show_progress,
    "quiet"     =>\$g_quiet,
    "user=s"    =>\$g_user,
    "pass=s"    =>\$g_pass,
    "summary=s" =>\$g_summary,
    "labels=s"  =>\$g_labels,
    "debug"     =>\$g_debug,
    "help"      =>\$g_help,
    "version"   =>\$g_version,
    );

## --- globals.  -ends-

&doit();
# won't be here

sub doit()
{
    my $result=GetOptions(%g_options);
    exit(1)  if (!$result);
    &usage() if ($g_help);
    if ($g_version)
    {
        print "$me v${g_version_s}\n";
        exit(1);
    }

    $g_os=&os_type();
    &print_debug("OS: $g_os");

    # check if all necessary args are specified
    &check_args();

    &print_debug("File: '$g_file'");
    &print_debug("Project: '$g_project'");
    &print_debug("User: '$g_user'");
    &print_debug("Pass: '$g_pass'");
    &print_debug("Summary: '$g_summary'");
    &print_debug("Lables: '$g_labels'");

    if (! -f $g_file)
    {
        &print_fatal("\nFile '$g_file' does not exist. exiting..");
    }
    my $curl_args=&build_curl_args();
    &print_debug("$curl_args");

    # ok run curl now
    &run_cmd($curl_args);

    exit(0);
}

sub build_curl_args()
{
    my $url="https://${g_project}.${g_domain}${g_loc}";
    # split lablels
    if ($g_labels)
    {
        my $lab_arg='';
        my @a=split(',',$g_labels);
        if (scalar(@a))
        {
            my $l;
            foreach $l (@a)
            {
                $lab_arg .= "-F label=\"${l}\" ";
            }
            $lab_arg =~ s/\s$//g;
            $g_labels="$lab_arg";
        }
        else
        {
            $g_labels="-F $g_labels";
        }
    
    }
    my $curl_args="${g_curl_path} -u \"${g_user}:${g_pass}\" -F summary=\"${g_summary}\" -F upload=\@${g_file}";
    if ($g_labels)
    {
        $curl_args .=" $g_labels";
    }
    if ($g_show_progress)
    {
        $curl_args .=" -#";
    }
    else
    {
        if ($g_quiet)
        {
            $curl_args .=" -s";
        }
    }
    $curl_args .=" ${url}";
    return($curl_args);
}

sub run_cmd()
{
    my $cmd=shift;
    local *FD;
    open(FD,"$cmd |") or &print_fatal("could not run $cmd");
    my @lines=(<FD>);
    my $line;
    foreach $line (@lines)
    {
        chomp($line);
        print "$line\n";
    }
    close(FD);
}

sub check_args()
{
    my $err='';
    if (!$g_file)
    {
        $err .="    Error: Filename must be specified with --file";
    }
    if (!$g_project)
    {
        if ($err)
        {
            $err .= "\n";
        }
        $err .="    Error: Project name must be specified with --project";
    }
    if (!$g_summary)
    {
        if ($err)
        {
            $err .= "\n";
        }
        $err .="    Error: Summary must be specified with --summary";
    }
    if (!$g_user)
    {
        if ($err)
        {
            $err .= "\n";
        }
        $err .="    Error: Username must be specified with --user";
    }
    if ($err)
    {
        $err .="\n\n    Please type '$me --help' for more info\n";
        &print_fatal($err);
    }
        
    &print_debug("Project: '$g_project'");
#    &print_fatal("Project name must be specified with --project") if (!$g_project);
#    &print_fatal("Summary must be specified with --summary")      if (!$g_summary);
#    &print_fatal("Username must be specified with --user")        if (!$g_user);
    if (!$g_pass)
    {
        if ($ENV{GOOGLECODE_PASS})
        {
            $g_pass=$ENV{GOOGLECODE_PASS};
        }
        else
        {
            $g_pass=&my_getpass("Enter googlecode password: ");
            &print_fatal("\nPassword can not be empty") if (!$g_pass);
        }
    }
}

sub usage()
{
    print<<EOF;
${me} v${g_version_s}
A script to updload files to googlecode

Usage: ${me} options
Where the options include:
 -f,    --file=file            File to upload
 -s,    --summary=description  Short description of the file
 -proj, --project=name         googlecode project name
 -prog, --progress             Show upload progress
 -u,    --user=user            googlecode user name
 -pass, --pass=password        googlecode password
 -l,    --label=labels         Comma separated label names
 -d,    --debug                Show debug information
 -h,    --help                 Show this help
 -v,    --version              Show version information

Example:
  \$ $me -summary="Latest source"
      --project="testxyz" 
      --user="muquit" --pass="xxxx" 
      --labels="Featured,Featured" --file=testxyz.tar.gz

 Password can be set by env GOOGLECODE_PASS. If password is not specified
 in anyway, it'll be prompted.
 \$ export GOOGLECODE_PASS="secret"
 \$ $me -s="Latest source"
      -project="testxyz" 
      -user="muquit"
      -labels="Featured" --file=testxyz.tar.gz


EOF
;
    exit(1);
}

##-----
# print debug message to stderr if debugging is on
##-----
sub print_debug()
{
    my $msg=shift;

    return if (!$g_debug);
    return if (!$msg);

    my $lno=(caller(0))[2];
    my $t=localtime(time());
    print STDERR "$t ($lno): $msg\n";
}

##-----
# print the message to stderr and exit
##-----
sub print_fatal()
{
    my $msg=shift;
    print "$msg\n";
    exit(1);
}

##-----
# prompt for password
##-----
sub my_getpass
{
    my $prompt=shift || "Enter password:";
    my $pass='';
    my $c;
    local *FD;
    return if (! -t STDOUT and ! -t STDIN);

    if ($g_os eq "unix")
    {
        open (FD,"/dev/tty") or die "Could open /dev/tty $!";
        system("stty -echo");
        system("stty raw"); 
    }
    else
    {
        *FD=*STDIN;
    }

    print STDOUT "$prompt";
    while ($c=getc(FD))
    {
        my $x=unpack("C*",$c);
        if ($x eq '3') # Ctrl-C
        {
            &reset_tty();
            close(FD) if ($g_os eq "unix");
            return('');
        }
        last if ($c eq "\n");
        last if ($c eq "\r");
        if ($g_os eq "unix")
        {
            print "*";
        }

        $pass .= $c;
    }


    if ($g_os eq "unix")
    {
        &reset_tty();
        close(FD);
    }
    return ($pass);
}

##-----
# reset tty
##-----
sub reset_tty()
{
    if ($g_os !~ /mswin32/i)
    {
        system("stty sane");
        system("stty echo");
        system("stty erase ");
    }
}

##---
# returns "unix" if it is not mswin32
##---
sub os_type()
{
    my $os=$^O;
    &print_debug("OS is: $os");
    if ($os !~ /mswin32/i)
    {
        $os="unix";
    }
    return($os);
}

##----
# catch interrupt
##----
sub catch_intr()
{
    if ($g_os !~ /mswin32/i)
    {
        system("stty sane");
    }
    &print_debug("\nInterrupt detected..");
}

1;

__END__

=head1 NAME

googlecode_upload.pl - A script to upload files to googlecode.com

=head1 AUTHOR

Muhammad Muquit, http://www.muquit.com/

=cut
