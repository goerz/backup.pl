#!/usr/bin/perl -w
use strict;
use Env;


my $profile = shift @ARGV;
unless (-f $profile){
    die "Profile not found\n\nusage: backup.pl profile.bkp\n"
}


my %exclusions;
my @filters;

my $maxsize = 0;
my $splitsize = 0;
my $gzip = 0;
my $outfile = '';
my $postcommand;


my $tempfolder = $ENV{HOME} . "/.backup.pl";
mkdir($tempfolder) unless (-d $tempfolder);

my $filelist = "$tempfolder/backup.filelist";
if ($profile =~ m'^.*?/?([^/]+)$'){ # extract everything after the last slash
    $filelist = "$tempfolder/$1.filelist";
}

open(FILELIST, ">$filelist") or die ("Can't write to $filelist\n");
close FILELIST;

# parse the profile
open(PROFILE, $profile) or die ("Can't open $profile\n");
my $mode = "include";
foreach my $line (<PROFILE>){
    chomp $line;
    if      ($line =~ /# INCLUDE/   ){
        $mode = "include"
    } elsif ($line =~ /# EXCLUDE/   ) {
        $mode = "exclude"
    } elsif ($line =~ /# VARIABLES/) {
        $mode = "variables"
    } else {
        unless ($line =~ /^\s*$/){ # discard empty lines
            if      ($mode eq "include"  ){
                system("$line >> $filelist");
            } elsif ($mode eq "exclude"  ){
                foreach (readpipe($line)){
                    $exclusions{$_} = 1;
                }
            } elsif ($mode eq "variables"){
                $maxsize = $1 if ($line =~ /maxsize = ([0-9]+)/);
                $splitsize = $1 if ($line =~ /splitsize = (.+)/);
                eval("push(\@filters, qw$1)") if ($line =~ /excludepattern = (.+)/);
                $gzip = $1 if ($line =~ /gzip = (0|1)/);
                $outfile = $1 if ($line =~ /outfile = (.+)/);
                system($1) if ($line =~ /precommand = (.+)/);
                $postcommand = $1 if ($line =~ /postcommand = (.+)/);
            }
        }
    }
}

my $counter = 1;
my $bytes = 0;

my $megabyte =    1048576;

print "$profile:\n";

# split up the list
my @tarlists; # the list of all splitup-lists
open( FILELIST, "<utf8", "$filelist") or die ("Couldn't open $filelist\n");
open( SMALLLIST, ">utf8", "${filelist}.${counter}") or die ("Couldn't open ${filelist}.${counter}\n");
foreach my $file (<FILELIST>){
    chomp $file;
    my $size = (stat($file))[7];
    $size = 0 unless defined($size);

    if (  ( (($size / $megabyte) < $splitsize) or ($splitsize == 0) ) and (not (is_excluded($file))) and (not (is_filtered($file)))  ){
        if (  ((($bytes + $size) / $megabyte) >= $splitsize) and ($splitsize != 0)  ){ # start new list
            printf("Finished filelist for volume %i with %f bytes (%f MB)\n", $counter, $bytes, $bytes/$megabyte);
            close SMALLLIST;
            push(@tarlists, "${filelist}.${counter}");
            $counter++;
            open( SMALLLIST, ">utf8", "${filelist}.${counter}") or die ("Couldn't open ${filelist}.${counter}\n");
            $bytes = 0;
        }
        $bytes += $size;
        print SMALLLIST $file, "\n";
    }

}
printf("Finished filelist for volume %i with %f bytes (%f MB)\n\n", $counter, $bytes, $bytes/$megabyte);
close SMALLLIST;
push(@tarlists, "${filelist}.${counter}");

# tar each file list
my $i = 1;
my $time = `date +%F_%H%M`;
foreach my $file (@tarlists){
    print "\nTaring $file....\n";
    chomp $time;
    if ($gzip){
        system("tar --files-from=$file --create --no-recursion --gzip --file=$outfile.$time.$i.tgz");
    } else {
        system("tar --files-from=$file --create --no-recursion --file=$outfile.$time.$i.tar");
    }
    $i++;
    print "Done\n"
}


system($postcommand) if ((defined($postcommand)) and ($postcommand ne ''));



sub is_excluded{
    my $file = shift;
    if ( (exists($exclusions{$file})) and ($exclusions{$file} == 1) ){
        return 1;
    } else {
        return 0;
    }
}

sub is_filtered{
    my $file = shift;
    foreach my $filter (@filters){
        return 1 if ($file =~ $filter);
    }
    return 0;
}