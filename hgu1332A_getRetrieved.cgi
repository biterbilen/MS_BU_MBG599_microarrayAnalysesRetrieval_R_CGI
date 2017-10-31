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

my $title = "Retrival of Single DEG Analysis";
my ($html);
$html= eval { new HGU1332A_HtmlPages(); }  or die ($@);
$html->_title($title);
$html->_target('_parent');
$html->_jscript($JSCRIPT);
$html->_pageTitle($title);
$html->printU1332A_Header();
$html->printU1332A_PageTitle();
#######################################################################################
#set the parameters
my $parH = Vars;

#######################################################################################
# HERE IS THE ANALYSIS PART
#######################################################################################
my $db = eval { new HGU1332A_DBPages($parH->{'aID'}); }  or die ($@);
my @table;
my @tableTitle;

$db->selectData($parH, \@table, \@tableTitle);

#######################################################################################
my $fileN = 'hgu_tmp/' . $parH->{'aID'} . $parH->{'qtype'} . $parH->{'TYPE'} . $parH->{'FDR'} . $parH->{'FDRT'} . $parH->{'REG'} . '.csv';
$html->print_print2File(\@table, \@tableTitle, $fileN);

$html->print_getRetrieved(\@table, \@tableTitle);
#$html->print_getRetrieved(\@table, \@tableTitle, $queryAnnotRef);

print "<div>", Dump(), "</div>";
$html->printU1332A_Footer();

exit;

#######################################################################################

