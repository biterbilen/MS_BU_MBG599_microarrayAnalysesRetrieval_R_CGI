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

my $title;
my $job = param('job');
$title = "Merge Two DEG Analyses" if ($job eq 'merge');
$title = "Retrieve Single DEG Analysis" if ($job eq 'retrieve');

my ($html);
$html= eval { new HGU1332A_HtmlPages(); }  or die ($@);
$html->_title($title);
$html->_target('_parent');
$html->_jscript($JSCRIPT);
$html->_pageTitle($title);
$html->printU1332A_Header();
$html->printU1332A_PageTitle();
#######################################################################################

my $aID = param('aID');
my $db = eval { new HGU1332A_DBPages($aID); }  or die ($@);

##################################
#retrieve analyzed pairs values
my @pairA = ();
$db->getDataSorted($aID, 'HGUmetaDataPair', 'pairvalue', \@pairA);

#retrieve proc
my @procA = ();
$db->getDataSorted($aID, 'HGUmetaDataProc', 'proc', \@procA);

#######################################################################################
$html->print_retrieve(\@pairA, \@procA) if ($job eq 'retrieve');
$html->print_merge(\@pairA, \@procA) if ($job eq 'merge');
#$html->print();

#######################################################################################
#retrieve analyzed data
my @dataA = ();
$db->getData($aID, 'HGUmetaData', 'aid,norMet,expLim,ttest', \@dataA);

#retrieve analyzed pairs Label 
my @dataL = ();
$db->getData($aID, 'HGUmetaDataPair', 'pairlabel', \@dataL);

$html->print_metaData(\@dataA, \@dataL); 

print "<div>", Dump(), "</div>";
$html->printU1332A_Footer();

exit;

#######################################################################################

