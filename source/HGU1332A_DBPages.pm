# class HGU1332A_DBPages
package HGU1332A_DBPages;

use strict;
use warnings;
use CGI qw/:standard :html3 :cgi-lib/;
use CGI::Carp qw(fatalsToBrowser);
use DBI;

use lib './source/';
use base qw(HGU1332A_DB);    # inherits from HGU1332A_DB

my $verbose = 0;
####################################################################################
#constructor
sub new {
    my ($class, $aID) = @_;

    #call the constructor of the parent class, HGU1332A_DB
    my $self = $class->SUPER::new();

    $self->{_tag}	= "HGU";
    $self->{_aID}	= $aID;

    bless $self, $class;
    return $self;
}

####################################################################################
sub dropTable {
    my ($self, $tableN) = @_;

    my $dropSt = getDropStmt($tableN);
#print p("$dropSt;");
    my $dbh = $self->connect;

    #drop the old data if a table exits
    $dbh->do($dropSt) or die("Can't execute $dropSt: $dbh->errstr\n");
    $self->disconnect($dbh);
}

sub createTable {
    my ($self, $tableN, $labelRef, $procRef) = @_;

    my $createSt = getCreateStmt($tableN, $labelRef, $procRef);
print p("$createSt;") if($verbose);
    my $dbh = $self->connect;

    #create the table
    $dbh->do($createSt) or die("Can't execute $createSt: $dbh->errstr\n");
    $self->disconnect($dbh);

}

sub insertTable {
    my ($self, $tableN, $inFileN, $labelRef, $type, $procRef) = @_;
    my $insertSt = getInsertStmt($tableN, $labelRef, $procRef);
print "<br>$insertSt<br>" if ($verbose);
    my $pdecP = 10;
    my $dbh = $self->connect;

    my($result,$stmth);

    $stmth = $dbh->prepare($insertSt);
    open (F, "$inFileN") or die "$inFileN\t $!";
    my $title = <F>;
    my $procStartIn = 16;
    my $procEndIn = getProcEndIn($title, $procStartIn);
    while(<F>)
    {
        chomp $_;
        $_ =~ s/[\b\s]$//;
        my @tmp = split("\t", $_);

	#regulation	
        if ($tmp[1] >= 0) { $tmp[1] = 13; }
        else { $tmp[1] = 23; }

	#p-values
	for (my $i = $procStartIn; $i < $procEndIn; $i++) {
	     $tmp[$i] = sprintf("%.${pdecP}f", $tmp[$i]);
	}
	
	#do not forget to insert the type in the beginning
	unshift(@tmp, $type);

print "$tmp[1] " if ($verbose);

        $result = $stmth->execute(@tmp) or
                        die("Could not add: @tmp\n" . $stmth->errstr );
    }
    close F;

    $self->disconnect($dbh);
}

sub loadMetaDBTable {
    my ($self, $parH) = @_;

    my $metaInsSt   =<<"DB_INSERT_STMT";
INSERT INTO `$self->{_tag}metaData`
(aid, time, norMet, expLim, ttest) VALUES (?,?,?,?,?)
DB_INSERT_STMT
    chomp $metaInsSt;

    my $dbh = $self->connect;

    my($result,$stmth);
    $stmth = $dbh->prepare($metaInsSt);

    my $metaDelSt = "DELETE from `$self->{_tag}metaData` where aid=$parH->{'aID'}";
#print p($metaDelSt);
    $dbh->do($metaDelSt) or die("can't execute $metaDelSt: $dbh->errstr\n");

    my @tmp;
    push (@tmp, $self->{_aID});
    push (@tmp, getTime());
    push (@tmp, $parH->{'norm'});
    push (@tmp, $parH->{'explimit'});
    push (@tmp, "$parH->{'tttype'} $parH->{'tttail'} $parH->{'ttvar'}");
    $result = $stmth->execute(@tmp) or
                        die("Could not add: $_" . $stmth->errstr );
   
    $self->disconnect($dbh); 
}

sub loadMetaProcDBTable {
    my ($self, $parH, $procRef ) = @_;

    my $metaInsSt   =<<"DB_INSERT_STMT";
INSERT INTO `$self->{_tag}metaDataProc`
(aid, proc) VALUES (?,?)
DB_INSERT_STMT
    chomp $metaInsSt;

    my $dbh = $self->connect;

    my($result,$stmth);
    $stmth = $dbh->prepare($metaInsSt);

    my $metaDelSt = "DELETE from `$self->{_tag}metaDataProc` where aid=$parH->{'aID'}";
#print p($metaDelSt);
    $dbh->do($metaDelSt) or die("can't execute $metaDelSt: $dbh->errstr\n");

    foreach(@$procRef) {
	my @tmp;
	push (@tmp, $parH->{'aID'});
	push (@tmp, $_);
	$result = $stmth->execute(@tmp) or
                        die("Could not add: @_" . $stmth->errstr );
    }    
    $self->disconnect($dbh); 

}

sub loadMetaPairDBTable {
    my ($self, $parH, $valueRef, $labelRef) = @_;

    my $metaInsSt   =<<"DB_INSERT_STMT";
INSERT INTO `$self->{_tag}metaDataPair`
(aid, pairvalue, pairlabel) VALUES (?,?,?)
DB_INSERT_STMT
    chomp $metaInsSt;

    my $dbh = $self->connect;

    my($result,$stmth);
    $stmth = $dbh->prepare($metaInsSt);

    my $metaDelSt = "DELETE from `$self->{_tag}metaDataPair` where aid=$parH->{'aID'}";
#print p($metaDelSt);
    $dbh->do($metaDelSt) or die("can't execute $metaDelSt: $dbh->errstr\n");

    for(my $i = 0; $i < scalar @$labelRef; $i++) {
	my @tmp;
	push (@tmp, $parH->{'aID'});
	push (@tmp, $valueRef->[$i]);
	push (@tmp, $labelRef->[$i]);
	$result = $stmth->execute(@tmp) or
                        die("Could not add: $_" . $stmth->errstr );
    }    
    $self->disconnect($dbh); 
}
####################################################################################
sub selectData {
   my ($self, $parH, $tableRef, $tableTitleRef) = @_;

   my $tableN = $self->formTableName('data');

   my $condition = "REG LIKE '%$parH->{'REG'}%' and TYPE='$parH->{'TYPE'}' and $parH->{'FDR'} > `$parH->{'FDRT'}`  "; 
   my $annotFields = getFields($parH);
   my $expFields = getExpFields($self, $parH->{'aID'}, $parH->{'TYPE'});
   my $fields = ($annotFields.",".$expFields);

   my $dbQueryStmt;
   my @table;
   if ($parH->{'query'} eq '*') { 
   	$dbQueryStmt = "SELECT $fields FROM `$tableN` WHERE $condition";
#print p ($dbQueryStmt);
   	$self->setRow(\$dbQueryStmt,\@table);
   }
   else {
	my $addCondition = "and $parH->{'qtype'}=";
	my $idS = $parH->{'query'};
	my @ids = split(/[\b\s]/, $parH->{'query'});
	foreach my $id (@ids) {
	    $id =~ s/[\s\b]//g;
	    my @tmp;
   	    $dbQueryStmt = "SELECT $fields FROM `$tableN` WHERE $condition$addCondition'$id'";
#print p ($dbQueryStmt);
    	    $self->setRow(\$dbQueryStmt,\@tmp);
	    push(@table, @tmp);
	}
    }

    #don't forget to merge the intensities if qtype=SYMBOL specified
    if ($parH->{'qtype'} eq 'SYMBOL') {
	my @expStartA = split(",",$annotFields); 
    	my $expStartIndex = scalar @expStartA;
    	my @rowCountA = split(",",$fields);
    	my $rowCount = scalar @rowCountA;
	my $symbolIndexH = {};
	getSymIndex($symbolIndexH, \@table, $rowCount);
    	mergeIntensities($symbolIndexH, $expStartIndex, $rowCount, \@table, $tableRef);
    }
    else {
	@$tableRef = @table;
    }
    @$tableTitleRef = split(",",$fields) if (scalar @$tableRef) ;
}

sub selectMergedData {
    my ($self, $parH, $tableRef, $tableTitleRef) = @_;

    my $tableN = $self->formTableName('data');
    my ($dbQueryStmt, $condition);

    #always merge on ID since it is the unique one!!!
    #first group
    my @group1;
    $condition = "REG LIKE '%$parH->{'REG'}%' and TYPE='$parH->{'TYPE'}' and $parH->{'FDR'} > `$parH->{'FDRT'}`  "; 
    $dbQueryStmt = "SELECT ID FROM `$tableN` WHERE $condition"; 
#print p ($dbQueryStmt);
    $self->setRow(\$dbQueryStmt,\@group1);

    #second group
    my @group2;
    $condition = "REG LIKE '%$parH->{'REG2'}%' and TYPE='$parH->{'TYPE2'}' and $parH->{'FDR2'} > `$parH->{'FDRT2'}`  "; 
    $dbQueryStmt = "SELECT ID FROM `$tableN` WHERE $condition";
#print p ($dbQueryStmt);
    $self->setRow(\$dbQueryStmt,\@group2);

    $condition = "REG LIKE '%$parH->{'REG'}%' and TYPE='$parH->{'TYPE'}' and $parH->{'FDR'} > `$parH->{'FDRT'}`  "; 
    my $expFields = getExpFields($self, $parH->{'aID'}, $parH->{'TYPE'});
    my $expFields2 = getExpFields($self, $parH->{'aID'}, $parH->{'TYPE2'});
    my $annotFields = getFields($parH);
    my $uniExpFields = unifyExpFields($expFields, $expFields2);
    my $fields = ($annotFields.",".$uniExpFields);

    my @ids = ();
    my @table;
    mergeArrays(\@group1, \@group2, \@ids);
#print p(scalar @ids);
#print p(@ids);
    my $addCondition = "and ID=";
    for( my $i= 0; $i < scalar @ids; $i++) {
	my $id = $ids[$i];
	my @tmp;
   	$dbQueryStmt = "SELECT $fields FROM `$tableN` WHERE $condition$addCondition'$id'";
    	$self->setRow(\$dbQueryStmt,\@tmp);
	push(@table, @tmp);
    }

    #don't forget to merge the intensities if qtype=SYMBOL specified
    if ($parH->{'qtype'} eq 'SYMBOL') {
	my @expStartA = split(",",$annotFields); 
    	my $expStartIndex = scalar @expStartA;
    	my @rowCountA = split(",",$fields);
    	my $rowCount = scalar @rowCountA;
	my $symbolIndexH = {};
	getSymIndex($symbolIndexH, \@table, $rowCount);

    	mergeIntensities($symbolIndexH, $expStartIndex, $rowCount, \@table, $tableRef);
    }
    else {
	@$tableRef = @table;
    }
    @$tableTitleRef = split(",",$fields) if (scalar @$tableRef) ;
}

sub getData {
    my ($self, $aID, $tableN, $fields, $dataRef) = @_;

    my $dbQueryStmt = "SELECT $fields FROM `$tableN` WHERE aid=$aID";
    $self->setRow(\$dbQueryStmt,$dataRef);
}

sub getPairsMetaPairDB {
    my ($self, $aID, $pairRef) = @_;

    my $dbQueryStmt = "SELECT pairvalue FROM `HGUmetaDataPair` WHERE aid=$aID";
    $self->setRow(\$dbQueryStmt,$pairRef);
    @$pairRef = sort @$pairRef;
}

sub getDataSorted {
    my ($self, $aID, $tableN, $field, $dataRef) = @_;
    $self->getData($aID, $tableN, $field, $dataRef);
    @$dataRef = sort @$dataRef;
}

####################################################################################
sub print {
    my ($self) = @_;

    # we will call the print method of the parent class
    $self->SUPER::print;
}

####################################################################################
#PRIVATE routines
####################################################################################
sub getDropStmt {
    my ($tableN) = @_;

    return "DROP TABLE if EXISTS `$tableN`";
}

#TODO check type in case of problem
sub getCreateStmt {
    my ($tableN, $labelRef, $procRef) = @_;

    my $creSt = "CREATE TABLE `$tableN`";
    my $fields;
    $fields  =<<"FIELDS";
        (`TYPE`         varchar(30)    NOT NULL default '',
        `ID`            varchar(30)     NOT NULL default '',
        `REG`           varchar(2)      NOT NULL default '',
        `SYMBOL`        varchar(60)     NOT NULL default '',
        `ACCNUM`        varchar(60)     NOT NULL default '',
        `CHRLOC`        text            NOT NULL default '',
        `CHR`           integer(2)      NOT NULL default '',
        `ENTREZID`      varchar(60)     NOT NULL default '',
        `ENZYME`        text            NOT NULL default '',
        `GENENAME`      text            NOT NULL default '',
        `GO`            text            NOT NULL default '',
        `MAP`           text            NOT NULL default '',
        `OMIM`          text            NOT NULL default '',
        `PATH`          text            NOT NULL default '',
        `PMID`          text            NOT NULL default '',
        `REFSEQ`        text            NOT NULL default '',
        `UNIGENE`       text            NOT NULL default '',
FIELDS
    chomp $fields;
    my $priKey = "PRIMARY KEY (`TYPE`, `ID`))";

    my $procFields;
    getCreProcFields($procRef, \$procFields);

    my $expFields;
    getCreExpFields($labelRef, \$expFields);

    $creSt .= ($fields. $procFields . $expFields. $priKey);
    return $creSt;
}

sub getCreProcFields {
    my ($procRef, $expFieldsRef) = @_;

    my @tmp = ();
    
    foreach my $proc (@$procRef) {
    }

    my @procA = @$procRef;

    $$expFieldsRef = '';
    foreach (@procA) {
        $$expFieldsRef .=  "`$_`\t\tdecimal(2,10)\tNOT NULL default '',\n";
    }
}

sub getCreExpFields {
    my ($labelRef, $expFieldsRef) = @_;

    my @tmp = ();
    foreach my $label (@$labelRef) {
        my ($grp1, $grp2) = ($label =~ /([,\w]*) vs ([,\w]*)/);
        push(@tmp, split(",", $grp1));
        push(@tmp, split(",", $grp2));
    }

    my $fieldsH = {};
    foreach (@tmp) { $fieldsH->{$_} = 1; }

    $$expFieldsRef = '';
    foreach (sort keys %$fieldsH) {
        $$expFieldsRef .=  "`$_`\t\tdecimal(2,10)\tNOT NULL default '',\n";
    }
}

sub getInsertStmt {
    my ($tableN, $labelRef, $procRef) = @_;

    my $insStStart = "INSERT INTO `$tableN`";

    my $fields = 'TYPE,ID,REG,SYMBOL,ACCNUM,CHRLOC,CHR,ENTREZID,ENZYME,GENENAME,GO,MAP,OMIM,PATH,PMID,REFSEQ,UNIGENE';
    my $fieldsQuesMarks = '?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?';

    my ($procFields, $procFieldsQuesMarks);
    getInsProcFields($procRef, \$procFields, \$procFieldsQuesMarks);

    my ($expFields, $expFieldsQuesMarks);
    getInsExpFields($labelRef, \$expFields, \$expFieldsQuesMarks);

    my $insSt = "$insStStart ($fields$procFields$expFields) VALUES ($fieldsQuesMarks$procFieldsQuesMarks$expFieldsQuesMarks)";

    return $insSt;
}

sub getInsProcFields {
    my ($procRef, $procFieldsRef, $procFieldsQuesMarksRef) = @_;

    $$procFieldsRef =  "";
    $$procFieldsQuesMarksRef =  "";
    foreach (@$procRef) {
        $$procFieldsRef .=  ",`$_`";
        $$procFieldsQuesMarksRef .=  ",?";
    }
}

sub getInsExpFields {
    my ($labelRef, $expFieldsRef, $expFieldsQuesMarksRef) = @_;

    my @tmp = ();
    foreach my $label (@$labelRef) {
        my ($grp1, $grp2) = ($label =~ /([\W\w]*) vs ([\W\w]*)/);
        push(@tmp, split(",", $grp1));
        push(@tmp, split(",", $grp2));
    }
    my %fieldsH = ();
    foreach (@tmp) { $fieldsH{$_} = 1; }

    $$expFieldsRef = '';
    foreach (sort keys %fieldsH) {
        $$expFieldsRef .=  ",`$_`";
        $$expFieldsQuesMarksRef .=  ",?";
    }
}

sub getTime() {

    my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
    $Month = $Month + 1; # Months of the year are not zero-based

    if($Month < 10) {
        $Month = "0" . $Month; # add a leading zero to one-digit months
    }

    if($Day < 10) {
        $Day = "0" . $Day; # add a leading zero to one-digit days
    }

    $Year += 1900;

    if ($Hour < 10) {
        $Hour = "0" . $Hour;
    }

    if ($Minute < 10) {
        $Minute = "0" . $Minute;
    }

    if ($Second < 10) {
        $Second = "0" . $Second;
    }

    return("$Year-$Month-$Day-$Hour:$Minute:$Second");


}

sub setRow {
    my ($self, $dbQueryStmtRef,$resultsRef) = @_;
print "<div> $$dbQueryStmtRef </div>" if ($verbose == 1);
    my(@row);

    my $dbh = $self->connect;

    my $sth = $dbh->prepare($$dbQueryStmtRef) || die "can't prepare $dbQueryStmtRef";
    $sth->execute() || die "can't execute";
    while ( @row = $sth->fetchrow_array ) {
        push(@$resultsRef, @row);
    }

    $self->disconnect($dbh); 
}

#extracts information from metaDataPair
sub getExpFields {
    my ($self, $aID, $pairvalue) = @_;

    my @pairLabel;
    my $condition = "aid=$aID and pairvalue='$pairvalue'";
    my $dbQueryStmt = "SELECT pairlabel FROM `HGUmetaDataPair` WHERE $condition";
    $self->setRow(\$dbQueryStmt,\@pairLabel);

    $pairLabel[0] =~ s/ vs /,/g;
    return $pairLabel[0];     
}

sub getFields {
    my ($parH) = @_;

    #get annot values
    my @annotA = split("\0", $parH->{'annot'});
    my $annotH = {};
    foreach (@annotA) {
    	$annotH->{$_} = $_;
    }

    my $degF = '';
    $degF .= "ID" 	if ($parH->{'qtype'} eq 'ID');
    $degF .= "SYMBOL" 	if ($parH->{'qtype'} eq 'SYMBOL');
    if (defined $parH->{'TYPE2'}) { } #merge option is running
    else {
    	$degF .= ",RAWP";
#    	$degF .= ",ADJP";
    	$degF .= ",REG";
    }

    delete($annotH->{'SYMBOL'}) if ($parH->{'qtype'} eq 'SYMBOL');
    delete($annotH->{'ID'}) if ($parH->{'qtype'} eq 'ID');

    my $annotF = join(",", keys %$annotH);
    $annotF = ",$annotF" if ($annotF ne '');

    return ($degF.$annotF);
}

sub mergeArrays {
    my ($group1Ref, $group2Ref, $mergeRef) = @_;

    my $h1 = {};
    foreach(@$group1Ref) {
        $h1->{$_} = 1;
    }
    foreach(@$group2Ref) {
        push(@$mergeRef, $_) if (defined $h1->{$_});
    }
}

sub unifyExpFields {
    my ($expFields, $expFields2) = @_;

    my @a1 = split(",", $expFields);
    my @a2 = split(",", $expFields2);

    my $hash = {};
    foreach(@a1) {
	$hash->{$_} = 1;
    }

    foreach(@a2) {
	$hash->{$_} = 1;
    }
    return (join(",", sort keys %$hash));
}

sub mergeIntensities {
    my ($symbolIndexH, $firstExpIndex, $rowCount, $tableRef, $realTableRef) = @_;

    my @valueA = ();	
    foreach my $key (keys %$symbolIndexH) {

	#initialize valueA
	my $i;
	$valueA[0] = $key;
	for ($i = 1; $i < $firstExpIndex; $i++) {
	    $valueA[$i] = '';
	}
	for (; $i < $rowCount; $i++) {
	    $valueA[$i] = 0;
	}

	#sum the values into it
	my @symIndiceA = split(",", $symbolIndexH->{$key});
	for (my $i = 0; $i < scalar @symIndiceA; $i++) {
	    my $symIndex = $symIndiceA[$i];
	    my ($j, $k);
	    for($j = $symIndex+1, $k = 1; $k < $firstExpIndex; $j++, $k++) {
		if($symIndex == $symIndiceA[0]) {
	    	    $valueA[$k] .= "$tableRef->[$j]";
		}
		else {
	    	    $valueA[$k] .= ", $tableRef->[$j]";
		}
	    }
	    for(; $k < $rowCount; $j++, $k++) {
	    	$valueA[$k] += $tableRef->[$j];
	    }
	}

	#take the average now
	for(my $i = $firstExpIndex; $i < $rowCount; $i++) {
	    $valueA[$i] = $valueA[$i] / scalar @symIndiceA;
	}
	my $index = $symIndiceA[0];
	push(@$realTableRef, @valueA);
#print p(@valueA);
    }
}

sub getSymIndex {
    my ($symbolIndexH, $tableRef, $rowCount) = @_;
    for(my $i = 0; $i < scalar @$tableRef; $i = $i + $rowCount) {
	my $sym = $tableRef->[$i];
	if (defined $symbolIndexH->{$sym}) {
	    $symbolIndexH->{$sym} .= ",$i";
	}
	else {
	    $symbolIndexH->{$sym} = $i;
	}
    }
    delete($symbolIndexH->{'NA'});
}
sub getProcEndIn {
    my ($title, $startIn) = @_;
    my @arr = split("\t", $title);
    my $i;
    for($i = $startIn; $i < scalar @arr; $i++) {
	last if (substr($arr[$i], 0, 1) eq "X");
    }
    return $i;
}
#Package return value
############
1;
############
