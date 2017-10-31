#!/usr/bin/perl -w

use strict;
use warnings;
#use DBI;
use CGI qw/:standard :html3 :cgi-lib/;
use CGI::Carp qw(fatalsToBrowser);
use lib 'source/';
use HGU1332A_HtmlPages;
use HGU1332A_DBPages;

my $JSCRIPT;

my ($html);
$html= eval { new HGU1332A_HtmlPages(); }  or die ($@);
$html->_title('CEL File Load Database');
$html->_target('_parent');
$html->_jscript($JSCRIPT);
$html->_pageTitle('CEL File Load Database');
$html->printU1332A_Header();
$html->printU1332A_PageTitle();
#######################################################################################
#set the parameters
my $parH = Vars;
my @ttPairA 	=  split("\0", $parH->{'ttpairs'});
@ttPairA = sort @ttPairA;

my @pairLabelA 	= split("\0", $parH->{'pairlabels'});
my @pairValueA 	= split("\0", $parH->{'pairvalues'});
my @procA = split("\0", $parH->{'procs'});
@procA = sort @procA;

#extract ttPair labels
my $ttestpH = {};
foreach (@ttPairA) {
    $ttestpH->{$_} = 1;
}

for (my $i = 0; $i < scalar @pairValueA; $i++) {
    my $value = $pairValueA[$i];
    $ttestpH->{$value} = $pairLabelA[$i] if (defined $ttestpH->{$value});
}
#######################################################################################
if (@ttPairA == 0) {
    print
	p("Pick one t-test pair at least!!"),
	hr;
    exit;
}

#######################################################################################
# HERE IS THE ANALYSIS PART
#######################################################################################
print
   p(strong("Your Analysis ID is $parH->{'aID'}")
   ."<br>Later, you can retrieve information from the database with this ID"),
   p(strong("Constructing Meta Database...")
   ."<br>Normalization Method: $parH->{'norm'}"
   ."<br>Expression Value Limit: $parH->{'explimit'}"
   ."<br>t-test Paramaters: $parH->{'tttype'} $parH->{'tttail'} $parH->{'ttvar'}"     
   ."<br>Multiple Hypothesis Correction Procedure: @procA" 
   ."<br>t-test Pairs: " . join (', ', @pairValueA)); 
   hr;

#######################################################################################
my $db = eval { new HGU1332A_DBPages($parH->{'aID'}); }  or die ($@);

#insert tha analysis into meta database tables
$db->loadMetaDBTable($parH);
$db->loadMetaPairDBTable($parH, \@pairValueA, \@pairLabelA);
$db->loadMetaProcDBTable($parH, \@procA);

#######################################################################################
#drop and create data table
my $dataTableN = $db->formTableName('data');
$db->dropTable($dataTableN);
my @dbProcA = @procA;
unshift (@dbProcA, 'RAWP');
$db->createTable($dataTableN, \@pairLabelA, \@dbProcA);

#######################################################################################
#######################################################################################
#finally make analysis and insert entries into data tables
foreach my $pair (@ttPairA) {
    my $label = $ttestpH->{$pair};

    my $type = $label;
    $type =~ s/[\W]//g;
    my ($grp1, $grp2) = ($pair =~ /([\w\d]*) ([\w\d]*)/g);
    
    print
        strong("Loading $grp1-$grp2...");
    my $pValueFile = $parH->{'procdir'} . "$parH->{'norm'}_$grp1-${grp2}_pvals.txt";
    my $sqlFile = $parH->{'procdir'} . "$parH->{'norm'}_$grp1-${grp2}_sql\.txt";
    my $RlogFN = $parH->{'procdir'} . "_$parH->{'norm'}_$grp1-$grp2\.log";
    $html->print_loadDB($grp1, $grp2, $parH, $pValueFile, $sqlFile, $RlogFN, \@procA);
    print
        p(a({-href=>"$sqlFile", -target=>'_blank'}, "Significant Probe List")
        ."<br>" . a({-href=>"$pValueFile", -target=>'_blank'}, "p Value List"));

    $db->insertTable($dataTableN, $sqlFile, \@pairLabelA, $pair, \@dbProcA);
}

#######################################################################################
$html->print_loadDBForm($parH->{'aID'});
print "<div>", Dump(), "</div>";
$html->printU1332A_Footer();

exit;

#######################################################################################

