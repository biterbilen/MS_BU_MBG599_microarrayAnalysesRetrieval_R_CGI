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
$html->_title('CEL File Normalize');
$html->_target('_parent');
$html->_jscript($JSCRIPT);
$html->_pageTitle('CEL File Normalize');
$html->printU1332A_Header();
$html->printU1332A_PageTitle();

my $uploadDir = './fileUpload/';
my ($typeFN, $celFN);
$html->print_upload($uploadDir, \$typeFN, \$celFN);
my ($aID, $procDir);
$html->formProcDirName($uploadDir, $celFN, \$aID, \$procDir);
my $fileTypeHRef = {};
$html->parseTypeFile($uploadDir, $typeFN, $fileTypeHRef);
$html->prepareProcDir($uploadDir, $celFN, $typeFN, $fileTypeHRef, $procDir);

$html->print_normalizeForm($procDir, $typeFN, $celFN, $aID);
$html->print_preprocess($procDir);
#$html->print();
print "<div>", Dump(), "</div>";
$html->printU1332A_Footer();

exit;

#######################################################################################

