#!/usr/bin/perl -w

use strict;
use warnings;
#use DBI;
use CGI qw/:standard :html3 :cgi-lib/;
use CGI::Carp qw(fatalsToBrowser);
use lib 'source/';
use HGU1332A_HtmlPages;

my $JSCRIPT;

my ($html);
$html= eval { new HGU1332A_HtmlPages(); }  or die ($@);
$html->_title('CEL File Extract');
$html->_target('_parent');
$html->_jscript($JSCRIPT);
$html->_pageTitle('CEL File Extract');
$html->printU1332A_Header();
$html->printU1332A_PageTitle();


$html->print_extract();
#$html->print();
print "<div>", Dump(), "</div>";
$html->printU1332A_Footer();

exit;

#######################################################################################

