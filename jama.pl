#!/usr/bin/perl -w
use strict;

# use module
use XML::Simple;
use Data::Dumper;
use Unicode::String qw(latin1 utf8);


# Global settings
#my $terms = "\"N Engl J Med\"[Journal]+AND+has+abstract[filter]";
my $terms = "\"JAMA\"[Journal]+AND+has+abstract[filter]";
#$terms = "\"Lancet\"[Journal]+AND+has+abstract[filter]";
my $OUTFile = "jama.xml";

my $xml = new XML::Simple;
my $first = "first.xml";
my $second = "second.xml";
my $link = "link.xml";

# Subroutines
sub fetchNCBI {
    my ($file, $query) = @_;
    print "$query\n";

    if (-e $file) {
        unlink $file;
    }
    `wget -O $file '$query'`;
    if (not -e $file) {
        exit(-1);
    }
}

fetchNCBI($first, "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=100&usehistory=y&email=aaron\@cogent14.com&term=$terms");
my $data = $xml->XMLin($first);
my $querykey = $data->{QueryKey};
my $webenv = $data->{WebEnv};
fetchNCBI($second, "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&query_key=$querykey&rettype=full&WebEnv=$webenv&email=aaron\@cogent14.com&retstart=0&retmax=50");
my $data2 = $xml->XMLin("second.xml");

my @outXML;

my $curdate;
open FH, ">$OUTFile";
print FH "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
print FH "<data>\n";
foreach my $article (@{$data2->{PubmedArticle}}) {
    my $trueArt = $article->{MedlineCitation}->{Article};
    my $title = $trueArt->{ArticleTitle};
    my $abstract = $trueArt->{Abstract}->{AbstractText};
    my $page = $trueArt->{Pagination}->{MedlinePgn};
    my $issue = $trueArt->{Journal}->{JournalIssue}->{Issue};
    my $vol = $trueArt->{Journal}->{JournalIssue}->{Volume};
    my $dateYear = $trueArt->{Journal}->{JournalIssue}->{PubDate}->{Year};
    my $dateMon = $trueArt->{Journal}->{JournalIssue}->{PubDate}->{Month};
    my $dateDay = $trueArt->{Journal}->{JournalIssue}->{PubDate}->{Day};
    my $pmid = $article->{MedlineCitation}->{PMID}->{content};
    my $authors = "";

    my $trueabstract = "";
    if (ref($abstract) eq "ARRAY") {
        foreach my $subabstract (@{$abstract}) {
            $trueabstract .= $subabstract->{Label}.": ".$subabstract->{content}." ";
        }
    }
    $abstract = $trueabstract;

    fetchNCBI($link, "http://www.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=$pmid&retmode=xml&cmd=prlinks&email=aaron\@cogent14.com");
    my $linkxml = $xml->XMLin("link.xml");
    my $simplink = $linkxml->{LinkSet}->{IdUrlList}->{IdUrlSet}->{ObjUrl}->{Url};
    $simplink =~ s/&/&amp;/g;

    if (ref($trueArt->{AuthorList}->{Author}) eq "ARRAY") {
        my @authorsArr = ();
        foreach my $author (@{$trueArt->{AuthorList}->{Author}}) {
            if (exists $author->{LastName}) {
                push @authorsArr, $author->{LastName}." ".$author->{Initials};
            }
        }

        $authors = join(", ", @authorsArr);
    } else {
        if (exists $trueArt->{AuthorList}->{Author}->{CollectiveName}) {
            $authors = $trueArt->{AuthorList}->{Author}->{CollectiveName};
        } elsif (exists $trueArt->{AuthorList}->{Author}->{LastName}) {
            my $author = $trueArt->{AuthorList}->{Author};
            $authors = $author->{LastName}." ".$author->{Initials};
        }
    }
    my $citation = "$dateYear $dateMon $dateDay;$issue($vol):$page";
    my $date = "$dateMon $dateDay";
    $abstract =~ s/\. ([A-Z]+:)/.\n$1/g;

    if ($curdate eq "") {
        $curdate = $date;
        print FH "\t<date id='$curdate'>\n";
    } elsif (!($curdate eq $date)) {
        $curdate = $date;
        print FH "\t</date>\n";
        print FH "\t<date id='$curdate'>\n";
    }

#%hash = ('Title' => $title, 'PMID' => $pmid, 'Authors' => $authors, 'Citation' => $citation, 'Abstract' => $abstract);
#    push @outXML, %hash;

    $title = latin1($title);
    $authors = latin1($authors);
    $abstract = latin1($abstract);

    print FH "\t\t<article>\n";
    print FH "\t\t\t<title><![CDATA[".$title->utf8."]]></title>\n";
    print FH "\t\t\t<pmid>$pmid</pmid>\n";
    print FH "\t\t\t<authors><![CDATA[".$authors->utf8."]]></authors>\n";
    print FH "\t\t\t<citation>$citation</citation>\n";
    print FH "\t\t\t<abstract><![CDATA[".$abstract->utf8."]]></abstract>\n";
    print FH "\t\t\t<link>$simplink</link>\n";
    print FH "\t\t</article>\n";

#    print Dumper($trueArt);
#    exit;

}
print FH "\t</date>\n";
print FH "</data>\n";
close FH;
