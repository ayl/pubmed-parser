#!/usr/bin/perl -w

use strict;

my %TASKS = ("science.xml" => "/home/ayl/iphone/rss/server/pubmed/science.pl", "nature.xml" => "/home/ayl/iphone/rss/server/pubmed/nature.pl", "pnas.xml" => "/home/ayl/iphone/rss/server/pubmed/pnas.pl");

my @undone = keys %TASKS;
my $publishdir = "/home/ayl/public_html/scienceReader";

my $date = `date`;
chomp $date;
print "-----$date-----\n";
$date =~ s/\s//g;
$date =~ s/:/./g;

foreach my $task (@undone) {
    unlink $task;
}

while ($#undone > -1) {
    for (my $i = 0; $i <= $#undone; $i++) { 
        my $task = $undone[$i];
        `$TASKS{$task} 2>&1 1> /dev/null`;
        if (-e $task) {
            my $lines = `tail -n 1 $task`;
            chomp $lines;
            if ($lines =~ m/<\/data>/) {
                print "$task finished!\n";
                delete($undone[$i]);
            } else {
                print "$task FAILED: $lines\n";
            }
        }
        if ($#undone != -1) {
            sleep 10;
        }
    }
}

foreach my $task (keys %TASKS) {
    #`cp -f $task $publishdir`;
    #`mv -f $task $publishdir/$task.$date`;
    `mv -f $task $publishdir/$task`;
}


