#!/usr/bin/perl

# use module
use XML::Simple;
use Data::Dumper;
use Unicode::String qw(latin1 utf8);

$terms = "\"N Engl J Med\"[Journal]+AND+has+abstract[filter]";
$terms = "\"JAMA\"[Journal]+AND+has+abstract[filter]";
#$terms = "\"Lancet\"[Journal]+AND+has+abstract[filter]";

# create object
$xml = new XML::Simple;

# read XML file
if (-e "first.xml") {
    unlink "first.xml";
}
`wget -O first.xml 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=100&sort=pub+date&usehistory=y&email=aaron\@cogent14.com&term=$terms'`;
if (-e "first.xml") {
    $data = $xml->XMLin("first.xml");
} else {
    exit(-1);
}
$querykey = $data->{QueryKey};
$webenv = $data->{WebEnv};
if (-e "second.xml") {
    unlink "second.xml";
}
`wget -O second.xml 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&query_key=$querykey&rettype=full&WebEnv=$webenv&email=aaron\@cogent14.com&retstart=0&retmax=25'`;
$data2 = $xml->XMLin("second.xml");
# print output
#print Dumper($data2);

my @outXML;

my $curdate;
print "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
print "<data>\n";
foreach $article (@{$data2->{PubmedArticle}}) {
    $trueArt = $article->{MedlineCitation}->{Article};
    $title = $trueArt->{ArticleTitle};
    $abstract = $trueArt->{Abstract}->{AbstractText};
    $page = $trueArt->{Pagination}->{MedlinePgn};
    $issue = $trueArt->{Journal}->{JournalIssue}->{Issue};
    $vol = $trueArt->{Journal}->{JournalIssue}->{Volume};
    $dateYear = $trueArt->{Journal}->{JournalIssue}->{PubDate}->{Year};
    $dateMon = $trueArt->{Journal}->{JournalIssue}->{PubDate}->{Month};
    $dateDay = $trueArt->{Journal}->{JournalIssue}->{PubDate}->{Day};
    $pmid = $article->{MedlineCitation}->{PMID};
    $linkget = "wget -O link.xml 'http://www.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=$pmid&retmode=xml&cmd=prlinks&email=aaron\@cogent14.com'";
    `$linkget`;
    $linkxml = $xml->XMLin("link.xml");
#print Dumper($linkxml);
    $simplink = $linkxml->{LinkSet}->{IdUrlList}->{IdUrlSet}->{ObjUrl}->{Url};
    $simplink =~ s/&/&amp;/g;

    if (ref($trueArt->{AuthorList}->{Author}) eq "ARRAY") {
        @authorsArr = ();
        foreach $author (@{$trueArt->{AuthorList}->{Author}}) {
            if (exists $author->{LastName}) {
                push @authorsArr, $author->{LastName}." ".$author->{Initials};
            }
        }

        $authors = join(", ", @authorsArr);
    } else {
        if (exists $trueArt->{AuthorList}->{Author}->{CollectiveName}) {
            $authors = $trueArt->{AuthorList}->{Author}->{CollectiveName};
        } elsif (exists $trueArt->{AuthorList}->{Author}->{LastName}) {
            $author = $trueArt->{AuthorList}->{Author};
            $authors = $author->{LastName}." ".$author->{Initials};
        }
    }
    $citation = "$dateYear $dateMon $dateDay;$issue($vol):$page";
    $date = "$dateMon $dateDay";
    $abstract =~ s/. ([A-Z]+:)/.\n$1/g;

    if ($curdate eq "") {
        $curdate = $date;
        print "\t<date id='$curdate'>\n";
    } elsif (!($curdate eq $date)) {
        $curdate = $date;
        print "\t</date>\n";
        print "\t<date id='$curdate'>\n";
    }

#%hash = ('Title' => $title, 'PMID' => $pmid, 'Authors' => $authors, 'Citation' => $citation, 'Abstract' => $abstract);
#    push @outXML, %hash;

    $title = latin1($title);
    $authors = latin1($authors);
    $abstract = latin1($abstract);

    print "\t\t<article>\n";
    print "\t\t\t<title><![CDATA[".$title->utf8."]]></title>\n";
    print "\t\t\t<pmid>$pmid</pmid>\n";
    print "\t\t\t<authors><![CDATA[".$authors->utf8."]]></authors>\n";
    print "\t\t\t<citation>$citation</citation>\n";
    print "\t\t\t<abstract><![CDATA[".$abstract->utf8."]]></abstract>\n";
    print "\t\t\t<link>$simplink</link>\n";
    print "\t\t</article>\n";

#    print Dumper($trueArt);
#    exit;

}
print "\t</date>\n";
print "</data>\n";
