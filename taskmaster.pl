#!/usr/bin/perl -w

use strict;

my %TASKS = ("nejm.xml" => "/home/ayl/iphone/rss/server/pubmed/nejm.pl", "lancet.xml" => "/home/ayl/iphone/rss/server/pubmed/lancet.pl", "jama.xml" => "/home/ayl/iphone/rss/server/pubmed/jama.pl", "ophtho.xml" => "/home/ayl/iphone/rss/server/pubmed/ophthalmology.pl", "ajo.xml" => "/home/ayl/iphone/rss/server/pubmed/ajo.pl", "archivesOphtho.xml" => "/home/ayl/iphone/rss/server/pubmed/archivesOphtho.pl");

my @undone = keys %TASKS;
my $publishdir = "/home/ayl/public_html/medicalReader";

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


