#!/usr/bin/perl - so

use strict;
use warnings;
use CGI qw/:standard :html3/;
use CGI::Carp qw(fatalsToBrowser);
use lib 'source/';
use AffyHtmlPages;

my $JSCRIPT;

my ($affyWholeData);
$affyWholeData = eval { new AffyHtmlPages(); }  or die ($@);
$affyWholeData->_title('Whole Data Annotation');
$affyWholeData->_target('_parent');
$affyWholeData->_jscript($JSCRIPT);
$affyWholeData->_pageTitle('Whole Data Annotation');
$affyWholeData->printAffyHeader();
$affyWholeData->printAffyLinks();
$affyWholeData->printAffyPageTitle();

my ($query, $fields);
$fields = {
    _type       	=> undef, #probeID = 0 | geneSymbol = 1
};
setFields($fields, \$query);

#$affyWholeData->print();

$affyWholeData->printWholeDataPage($fields, \$query);
$affyWholeData->printAffyFooter();

exit;

#######################################################################################
sub setFields
{
    my ($fieldsRef, $queryRef) = @_;

    $fieldsRef->{_type}      = param('type');

    $$queryRef = param('mergedEntries');
#print "($$queryRef)";

}

