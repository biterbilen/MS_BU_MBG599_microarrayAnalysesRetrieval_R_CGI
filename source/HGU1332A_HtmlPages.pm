#class HGU1332A_HtmlPages
package HGU1332A_HtmlPages;

use DBI;
use CGI qw/:standard :html3/;
use CGI::Carp qw(fatalsToBrowser);
use strict;
use warnings;

use lib './source/';
use base qw(HGU1332A_Html);    # inherits from HGU1332A_Html
my $myRand  = 1;
#my $upload  = 0; my $CELFILE = 'ab.zip';
#my $upload  = 0; my $CELFILE = 'cd.zip';
#my $upload  = 0; my $CELFILE = 'selenyum3.zip';
#my $upload  = 0; my $CELFILE = 'selenyum23.zip';
#my $upload  = 0; my $CELFILE = 'selenyum2.zip';
my $upload  = 0; my $CELFILE = 'selenyum.zip';
#my $upload = 0; my $CELFILE = 'senescence.zip';
#my $upload = 0; my $CELFILE = 'senescence_gigs.zip';
#my $upload = 0; my $CELFILE = 'senescence_gigs2.zip';
my $prepare = 0;
my $preimage   = 0;
my $normalize = 0;
my $makeTTest = 0;
my $verbose = 0;

#constructor
sub new {
    my ($class) = @_;
    my $self = $class->SUPER::new();
    $self->{_Rexec} = '/home/oncogene/PROGRAMS/R/bin/R --vanilla';   
    bless $self, $class;
    return $self;
}

sub print_upload {
    my ($self, $uploadDir, $typeFNRef, $celFNRef) = @_;
    #system("kill 19833; kill 19834; kill 19835;");
    openPermissions('./fileUpload/typeFileSelenyum3');
    system('rm -rf ./fileUpload/typeFileSelenyum3');
    #UPLOAD THE FILES
    $$typeFNRef = uploadFile('type', $uploadDir);

    my $celFN;
    if ($upload) {
    	$$celFNRef  = uploadFile('cel', $uploadDir);
    }
    else {
    	$$celFNRef = $CELFILE;   
    }
}

sub print_preprocess {
    my ($self, $procDir) = @_;

    print strong("<br>Preprocessing...<br>"); 
    
    my @images = ();
    push(@images, param("rna"));
    push(@images, param("boxplot"));
    push(@images, param("hist"));
    push(@images, param("maplot"));
    push(@images, param("resids"));
    push(@images, param("rle"));
    push(@images, param("nuse"));

    #PREPROCESS; generate images
    my $Rcode = './source/preprocess.R';
    foreach my $im (@images) {
    	my $RlogFN	= "${procDir}_$im\.log";
    	my $Rargs = "$procDir $im";
    	runR($self->{_Rexec}, $Rcode, $Rargs, $RlogFN) if($preimage); 
	my $jpg = formJpegFileName($procDir, $im);
        openPermissions($procDir.'*');
	print p(strong("$im Image").br.img{-src=>$jpg, width=>600, height=>600, -align=>'justify', -alt=>"$im Image"});
    }  
    print hr;
}

sub print_normalizeForm{
    my ($self, $procDir, $typeFN, $celFN, $aID) = @_;

    #print normalization related fields
    my $norm = 
	radio_group(-name=>'norm',
                    -values=>['justrma', 'gcrma'],
		    -linebreak=>'true',
		    -labels => {justrma=> 'RMA (Irizarry et al., Robust Multichip Average, 2003b)', 
				gcrma=>'GCRMA (Wu & Irizarry, GeneChip RMA, 2004)'},
                    -default=>'justrma');
    print
	startform(-name=>'normalize',-action=>'hgu1332A_analyze.cgi'),
	p("Normalization method:<br>$norm"),
    	hidden({-name=>'procDir', -values=>[$procDir]}),
	hidden(-name=>'typeFN', -value=>[$typeFN]),
	hidden(-name=>'celFN', -value=>[$celFN]),
    	hidden({-name=>'aID', -values=>[$aID]}),
    	p(submit(-name=>'normalize', -value=>'Normalize')),
    	hr,
	endform;
}

sub print_analyze{
    my ($self) = @_;

    my $procDir = param('procDir');
    my $typeFN 	= param('typeFN');
    my $celFN  	= param('celFN');
    my $aID	= param('aID');
    my $norm 	= param('norm');
 
    print strong("<br>Normalizing...<br>"); 
    
    #NORMALIZE the files
    my $im = "boxplot_$norm";
    my $Rcode 	= './source/rma.R';
    my $RnormFN = "$procDir$norm\.csv";
    my $jpg = formJpegFileName($procDir, $im);
    my $Rargs 	= "$norm $procDir $RnormFN $jpg";
    my $RlogFN	= "${procDir}_$norm\.log";

    runR($self->{_Rexec}, $Rcode, $Rargs, $RlogFN) if ($normalize);

    #change permissions of files in $procDir
    openPermissions($procDir.'*');
    print 
	a({-href=>"$RnormFN", -target=>'_blank'}, "Normalized File"),
	p(strong("$im Image").br.img{-src=>$jpg, width=>600, height=>600, -align=>'justify', -alt=>"$im Image"}),
	hr;

    #remove procDir folder
    #system("rm -rf $procDir"); #TODO uncomment this line to clean server up

    #print analysis related fields
    my $cboxValuesA = [];
    my $cboxLabelsA = [];
    my $cboxLabelsH = {};

    #unify file names for database column processing 
    my $fileTypeHRef = {};
    $self->parseTypeFile($procDir, $typeFN, $fileTypeHRef);
    unifyForDatabaseColumn($fileTypeHRef);
    set_t_testPairs($cboxValuesA, $cboxLabelsA, $cboxLabelsH, $fileTypeHRef);

    my $explimit = textfield(-name => "explimit",
			     -size => "10",
		    	     -default => "4.0");
    my $ttType = radio_group(-name => "tttype",
			     -values=>['unpaired'],
			    #-values=>['paired','unpaired'],
                             -default=>'unpaired');
    my $ttTail = radio_group(-name => "tttail",
			     -values=>['twotailed'],
			    #-values=>['onetailed','twotailed'],
                             -default=>'twotailed');
    my $ttVar = radio_group(-name => "ttvar",
			     -values=>['unequal','equal'],
                             -default=>'unequal');
    my $ttPairs = checkbox_group(-name=>"ttpairs",
		-linebreak=> 'true',
    #		-labels => $cboxLabelsH, 
    		-values=>[@$cboxValuesA]);

    my $procs = checkbox_group(-name=>"procs",
			     -values=>['BH', 'BY', 'Bonferroni', 'Hochberg', 'Holm', 'SidakSD', 'SidakSS'],
			     -default=>'BH');
     
    print 
	startform(-name=>'analyze',-action=>'hgu1332A_loadDB.cgi'),
    	hidden({-name=>'aID', -values=>[$aID]}),
    	hidden({-name=>'norm', -values=>[$norm]}),
    	hidden({-name=>'normfile', -values=>[$RnormFN]}),
    	hidden({-name=>'procdir', -values=>[$procDir]}),
    	hidden({-name=>'pairvalues', -values=>[@$cboxValuesA]}),
    	hidden({-name=>'pairlabels', -values=>[@$cboxLabelsA]}),
	p("Expression Value Limit:<br>$explimit"),
	p("t-test Type:$ttType"."<br>t-test Tails:$ttTail"."<br>t-test Variance:$ttVar"),
	p("t-test Pairs:<br>$ttPairs"),
	p("Multiple Hypothesis Correction:<br>$procs"),
	p(submit(-name=>'analyze',
	   -value=>'Analyze')),
	hr,
	endform;
}


sub print_loadDB {
    my ($self, $grp1, $grp2, $parH, $pValueFile, $sqlFile, $RlogFN, $procA) = @_;

    #apply ttest
    my $procs = join(' ', @$procA); 
    my $Rcode = './source/ttest.R';
    my $Rargs = " $parH->{'tttype'} $parH->{'tttail'} $parH->{'ttvar'} $parH->{'explimit'} $grp1 $grp2 $parH->{'normfile'} $pValueFile $sqlFile $procs";

    runR($self->{_Rexec}, $Rcode, $Rargs, $RlogFN) if ($makeTTest);
    openPermissions($pValueFile);
    openPermissions($sqlFile);
}

sub print_loadDBForm {
    my ($self, $aID) = @_;

    print 
	startform(-name=>'loaddb',-action=>'hgu1332A_extract.cgi'),
    	hidden({-name=>'aID', -values=>[$aID]}),
	p(submit(-name=>'proceed',
	   -value=>'Proceed')),
	hr,
	endform;
}

sub print_extract{
    my ($self) = @_;

    my $aIDparam = param('aID');
    my $aID = textfield(-name => "aID",
			     -size => "10",
		    	     -default => $aIDparam);
    my $job = radio_group(-name=>'job',
                    -values=>['merge', 'retrieve'],
		    -linebreak=>'true',
		    -labels => {merge	=>'Merge Two t-test Analyses', 
				retrieve=>'Retrieve Single t-test Analysis'},
                    -default=>'retrieve');

    print 
	startform(-name=>'extract',-action=>'hgu1332A_job.cgi'),
    	p("Analysis ID: $aID"),
	p("Select job: <br>$job"),
	p(submit(-name=>'proceed',
	   -value=>'Proceed')),
   	hr,
	endform;
}

sub print_metaData {
    my ($self, $dataARef, $labelARef) = @_;

    my @pairs;
    foreach(@$labelARef) {
	push(@pairs, td([$_]) );
    }
    my $pairT = table({-border=>0, -align=>'justify'}, Tr(\@pairs));

    my @rows;
    push(@rows,td(["Analyis ID", $dataARef->[0]]));
    push(@rows,td(["Normalization Method", $dataARef->[1]]));
    push(@rows,td(["Expression Value Limit:", $dataARef->[2]]));
    push(@rows,td(["t-test Parameters", $dataARef->[3]]));
    push(@rows,td(["t-test Pairs", $pairT]));

    print
        table({-border=>0, -align=>'justify'},
            Tr(\@rows)),
        hr;


}
sub print_merge {
    my ($self, $pairARef, $procARef) = @_;

    my $aID = param('aID'); 

    my $submit = submit(-name=>'merge', 
                -value=>'Merge');

    my @rows;
    push(@rows,td([formParametersTable($pairARef, $procARef, "Group 1"), formParametersTable($pairARef, $procARef, "Group 2", '2')]));
    push(@rows,td([formFieldsTable()]));
    push(@rows,td([formQueryTypeTable("Output Type")]));
    push(@rows, td([$submit]));

    print
        start_form({-name=>"merge", -action=>'hgu1332A_getMerged.cgi'}), 
    	hidden({-name=>'aID', -values=>[$aID]}),
	"<div>",
        table({-border=>0, -align=>'justify'},
            Tr(\@rows)),
	"</div>",
        hr,
        end_form;

}

sub print_retrieve{
    my ($self, $pairARef, $procARef) = @_;
  
    my $submit = submit(-name=>'retrieve', 
                -value=>'Retrieve');

    my $aID = param('aID'); 
    my @rows;
    push(@rows,td([formParametersTable($pairARef, $procARef)]));
    push(@rows,td([formFieldsTable()]));
    push(@rows,td([formQueryTypeTable()]));
    push(@rows,td([formQueryTable()]));
    push(@rows, td([$submit]));

    print
        start_form({-name=>'retrieve',-action=>'hgu1332A_getRetrieved.cgi'}), 
    	hidden({-name=>'aID', -values=>[$aID]}),
        table({-border=>0, -align=>'justify'},
            Tr(\@rows)),
        end_form,
        hr;
}


sub print_getRetrieved {
    my ($self, $tableRef, $tableTitleRef) = @_;
    my $fieldsCount = scalar @$tableTitleRef;
    if ($fieldsCount == 0) {
        return;
    }
    printTable($tableRef, $tableTitleRef, $fieldsCount);
}

sub print_print2File {
    my ($self, $tableRef, $tableTitleRef, $fileN) = @_;

    my $fieldsCount = scalar @$tableTitleRef;
    if ($fieldsCount == 0) {
	print "<div>No match!!!<hr></div>";
        return;
    }

    open (O, ">$fileN") or die $!;

    print O join("\t", @$tableTitleRef) . "\n";
    my $i;
    foreach($i = 0; $i < scalar @$tableRef; $i = $i + $fieldsCount) {
    	foreach(my $j = $i; $j < scalar @$tableRef; $j++) {
    	    print O $tableRef->[$j] . "\t";
	}
	print O "\n";
    }

    close O;
    openPermissions($fileN);
    print a({-href=>"$fileN", -target=>'_blank'}, $fileN);
}

sub print_getMerged {
    my ($self, $type, $mergeInt, $mergedEntriesRef, $queryAnnotRef) = @_;
    my ($keyword);
    if ($type == 0) #PROBE ID
    {
	 $keyword = 'probes';
    }
    elsif ($type == 1) #GENE SYMBOL
    {
	 $keyword = 'genes';
    }
    my $mergedEntries = join("\n",@$mergedEntriesRef);
    print
    	start_form({-name=>"merged"}), #TODO OO
	hidden({-name=>'mergedEntries', -values=>[$mergedEntries]}),
	hidden({-name=>'type', -values=>[$type]}),
	hidden({-name=>'mergeInt', -values=>[$mergeInt]}),
    	$$queryAnnotRef,
    	submit(-name=>'submit',
		-value=>'ANNOTATE',
		-onClick=>"document.forms.merged.action = 'wholeData.cgi';"),
	p,
	b("Found ", scalar @$mergedEntriesRef, " $keyword:");
	p($mergedEntries);
    foreach(@$mergedEntriesRef)
    { 
    	print
	    "<br>$_";
    }
    print 
	end_form,
    	hr;
}

##########################################################
#private functions
##########################################################
sub formQueryTable
{
    my @rows;
    my $qr =
	textarea(-name=>'query',
	        -rows=>10,
		-default=>'*',
	        -columns=>40);

    push(@rows,td([$qr]));
    return
	table({-border=>6, -bordercolor=>'#326495'},
	    caption(strong('Input query here (* specifies all data)...')),
            Tr(\@rows));
}

sub formQueryTypeTable
{
    my ($caption) = @_;

    my @headings = ('Query Type');
    my @rows = th({-bgcolor=>'#6597C8'}, \@headings);

    my $merge = 
    	checkbox_group(-name=>"mergeInt",
                -labels=>{'1' => " Merge Intensities (mean)"}, 
		-values=>[1]);
    my $qt =
	radio_group(-name=>'qtype',
                -linebreak=>'true',
		-values=>['ID','SYMBOL'],
        	-labels=>{ID => 'Probe Id', SYMBOL => 'Gene Symbol'});

    #push(@rows,td(["$qt &nbsp&nbsp&nbsp $merge"]));
    push(@rows,td(["$qt"]));
    return
	table({-border=>2, -bordercolor=>'#326495'},
	    caption(strong($caption)),
            Tr(\@rows));
}

sub formFieldsTable
{
    my @headings = ('Annotation Fields');
    my @rows = th({-bgcolor=>'#6597C8'}, \@headings);

    my $annot =
    	checkbox_group(-name=>"annot",
                -linebreak=>'true',
		-values=>['ID','SYMBOL','ACCNUM','CHRLOC','CHR','ENTREZID','ENZYME','GENENAME','GO','MAP','OMIM','PATH','PMID','REFSEQ','UNIGENE'],
		-labels=>{ID=>'Affymetrix Probe Id', SYMBOL=>'Gene Symbol',ACCNUM=>'GenBank Accession Number',CHRLOC=>'Chromosomal Location',CHR=>'Chromosome',ENTREZID=>'Entrez Gene Id',
ENZYME=>'Enzyme Commission (EC) Id',GENENAME=>'Gene',GO=>'Gene Ontology (GO)',MAP=>'Cytogenetic Maps',OMIM=>'OMIM Id',
PATH=>'KEGG Pathway',PMID=>'PubMed Id',REFSEQ=>'RefSeq Id',SYMBOL=>'Gene Symbol',UNIGENE=>'UniGene Cluster Id'});

    push(@rows,td([$annot]));
    return
	table({-border=>2, -bordercolor=>'#326495'},
            Tr(\@rows));

}

sub formParametersTable {
    my ($pairARef, $procARef, $caption, $tag) = @_;

    my @headings = ('FDR', 'Gene Regulation', 'DEG Pair');
    my @rows = th({-bgcolor=>'#6597C8'}, \@headings);
    my $sg = radio_group(-name=>"TYPE$tag",
                -linebreak=>'true',
                -values=>$pairARef),
    my $fdrt = radio_group(-name=>"FDRT$tag",
                -linebreak=>'true',
		-values=>['RAWP',@$procARef],
		-default=>'RAWP');
    my $fdr = textfield(-name=>"FDR$tag",
		-size=>6,
                -default=>"0.001");
    my $gr = radio_group(-name=>"REG$tag",
                -linebreak=>'true',
                -values=>[1,2,3],
                -labels=>{1 => "Up", 2 =>"Down", 3 => "All"},
                -default=>3);

    push(@rows,td([$fdrt.$fdr,$gr,$sg]));
    return
	table({-border=>2, -bordercolor=>'#326495'},
	    caption(strong($caption)),
            Tr(\@rows));
}


sub printFileConversionWriteToImageFile
{
    my ($self, $tableRef, $tableTitleRef, $fieldsCount) = @_;
    #prepare Table file
    my ($i, $j);
    my $outF = "tmp/" . rand() . ".xls";
    open(O, ">$outF") or die $!;

    for ($i = 0; $i < $fieldsCount -1; $i++)
    {
	print O "$tableTitleRef->[$i]\t";
    }
    print O "$tableTitleRef->[$i]\n";

    for ($i = 0; $i < scalar @$tableRef; $i += $fieldsCount)
    {
	for($j = $i; $j < $i + $fieldsCount - 1; $j++)
	{
	    chomp $tableRef->[$j];
	    print O "$tableRef->[$j]\t"; 
	}	
	chomp $tableRef->[$j];
	print O "$tableRef->[$j]\n"; 
    }
    #write html script
    my $url = "./$outF";
    print
       	a({-href=>$url}, "Export Table to TAB Separated File");
}

sub prepareProcDir {
    my ($self, $uploadDir, $celFN, $typeFN, $fileTypeHRef, $procDir) = @_;

    return if ($prepare == 0);

    #create a tmp folder and extract the files in the .zip directory that are mentioned in the `Type` file here
    my $tmpDir = $procDir; $tmpDir =~ s/\/$/TMP\//; #ADD 'TMP' to the procDir name
    print p("mkdir $tmpDir;") if ($verbose);
    print p("cp $uploadDir$celFN $tmpDir; ") if ($verbose); #TODO replace this `cp` with `mv` in the end to clean up the server
    print p("unzip $tmpDir$celFN -d $tmpDir; ") if ($verbose);
    system("mkdir $tmpDir;");
    system("cp $uploadDir$celFN $tmpDir; "); #TODO replace this `cp` with `mv` in the end to clean up the server
    system("unzip $tmpDir$celFN -d $tmpDir; ");

    print p("rm -rf $procDir; mkdir $procDir;") if ($verbose); 
    system ("rm -rf $procDir; mkdir $procDir;");
    openPermissions($procDir);
    
    # mv the files in the tmp folder into procDir
    system("mv $uploadDir$typeFN ${procDir}.; "); 
    foreach my $celFile (keys %$fileTypeHRef) {
	my $newCelFile = renameFile($procDir, $fileTypeHRef->{$celFile}, $celFile);
	print p("mv $tmpDir$celFile $newCelFile;")  if ($verbose); 
	system("mv $tmpDir$celFile $newCelFile;");
    	openPermissions($newCelFile);
    }

    openPermissions("$uploadDir*");
    #remove tmpDir folder
    system("rm -rf $tmpDir");
}

sub printFileConversionWriteToClusterFile
{
    my ($self, $tableRef, $tableTitleRef, $fieldsCount) = @_;
    #prepare Cluster file
    my ($i, $j);
    my $outF = "tmp/" . rand() . ".xls";
    open(O, ">$outF") or die $!;
    my ($pIn, $gsIn, $gtIn);
    $pIn = -1;
    my $expIndex;
    for ($i = 0; $i < $fieldsCount; $i++) #only ProbeId&GeneSymbol OR GeneSymbol&GeneTitle
    {
	if ($tableTitleRef->[$i] =~ /Probe Id/) {
	    print O "$tableTitleRef->[$i]\t"; 
	    $pIn = $i;
	}
	if ($tableTitleRef->[$i] =~ /Gene Symbol/) {
	    print O "$tableTitleRef->[$i]\t"; 
	    $gsIn = $i;
	}
	if ($tableTitleRef->[$i] =~ /Gene Title/) {
	    print O "$tableTitleRef->[$i]\t"; 
	    $gtIn = $i;
	}
	if ($tableTitleRef->[$i] =~ /g11/)
	{
	    $expIndex = $i;
	    last;	
	}
    }
    for ($i = $expIndex; $i < $fieldsCount-1; $i++)
    {
	print O "$tableTitleRef->[$i]\t";
    }
    print O "$tableTitleRef->[$i]\n";

    for ($i = 0; $i < scalar @$tableRef; $i += $fieldsCount)
    {
	if ($pIn != -1) {
	    chomp $tableRef->[$i + $pIn];
 	    print O "$tableRef->[$i + $pIn]\t"; 
	}
	chomp $tableRef->[$i + $gsIn];
	print O "$tableRef->[$i + $gsIn]\t"; 
	chomp $tableRef->[$i + $gtIn];
	print O "$tableRef->[$i + $gtIn]\t"; 
	
	for($j = $i + $expIndex; $j < $i + $fieldsCount - 1; $j++)
	{
	    chomp $tableRef->[$j];
	    print O "$tableRef->[$j]\t"; 
	}	
	chomp $tableRef->[$j];
	print O "$tableRef->[$j]\n"; 
    }

    #write html script
    my $url = "./$outF";
    print
	#p("EXPINDEX: $expIndex-----"),
	p,
       	a({-href=>$url}, "Export Table to TAB Separated File for Clustering"),
	hr;
}

sub printTable
{
    my ($tableRef, $tableTitleRef, $fieldsCount) = @_;
    my @row;
    my @rows = th({-bgcolor=>'#6597C8'}, $tableTitleRef);
    my ($i, $j);
    my $entryNumber = scalar @$tableRef / $fieldsCount;
    for ($i = 0; $i < scalar @$tableRef; $i += $fieldsCount)
    {
	@row = ();
	for($j = $i; $j < $i + $fieldsCount; $j++)
	{
	    push(@row, td[$tableRef->[$j]]);	
	    #push(@row, td[$j]);	
	}
	push(@rows, Tr(@row));
    }
    my $end = 'y.';
    $end = 'ies.' if ($entryNumber > 1);
    print p("Found $entryNumber entr$end");

    print table({-border=>2, -align=>'justify', -bordercolor=>'#326495'},
		      	Tr(\@rows));
    print hr;
}

sub uploadFile {
    my ($par, $dir) = @_; 
    my $filename = param($par);
    $filename =~ s/.*[\/\\](.*)/$1/;
    my $upload_filehandle = upload($par);
    my $fileDir = "$dir$filename";
    open UPLOADFILE, ">$fileDir";
    binmode UPLOADFILE;
    while ( <$upload_filehandle> ) {
   	print UPLOADFILE;
    }
    close UPLOADFILE;
    openPermissions($fileDir);
    return $filename;
}

sub parseTypeFile {

    my ($self, $dir, $typeFN, $hashRef) = @_;
    open (F, "$dir$typeFN") or print "<div> $dir$typeFN opening problem </div>";
    my (@tmp);
    while (<F>) {
	if ($_ !~ /^%/) {
	    chomp $_;
	    @tmp = split("\t", $_);
	    $tmp[0] =~ s/([\s\b ]*)$//g;
	    $tmp[0] =~ s/^([\s\b ]*)//g;
	    $tmp[1] =~ s/([\s\b ]*)$//g;
	    $tmp[1] =~ s/^([\s\b ]*)//g;
	    $hashRef->{$tmp[0]} = $tmp[1];
	}
    }
    close F;
}

sub formProcDirName {
    my ($self, $uploadDir, $celFN, $aIDRef, $procDirRef) = @_;

    my $rand;
    if ($myRand) {
    	$rand = int(rand(100000));
    }
    else {
    	$rand = 10000;
    }
#TODO generate uncomment the 2 prev line

    my $celFNstart = substr($celFN, 0, index($celFN, '.'));
    #my $dir = "$uploadDir$rand${norm}_$celFNstart/";  #TODO uncomment this line and erase the following line
    my $dir = "$uploadDir$celFNstart/";
    $$aIDRef = $rand;
    $$procDirRef = $dir;
} 

#unify file names for database column processing 
sub unifyForDatabaseColumn {
    my($hashRef) = @_;

    my $newHash = {};
    foreach my $key (keys %$hashRef) {
	my $value = $hashRef->{$key};
	$newHash->{renameColumn($value,$key)} = $value;
    }

    %$hashRef = %$newHash;
}

#the labels will later be the column names of the expression sets
sub set_t_testPairs {
    my ($keyPairsARef, $labelPairsARef, $labelPairsHRef, $fileHRef) = @_;

    #select distict types as values of file names that belong to that type
    my $typeH;
    foreach(keys %$fileHRef) {
	my $value = $fileHRef->{$_};
	$typeH->{$value} = 1;
    }
    #fetch the names of files for each type
    foreach(keys %$typeH) {
	my $type = $_;
	$typeH->{$type} = fetchValueKeys($type, $fileHRef);	
    }


    my @keys = sort keys %$typeH;
#print p("these are the keys: @keys");
    #form, at last, pairs

    for (my $i = 0; $i < (scalar @keys - 1); $i++) {
    	for (my $j = $i+1; $j < scalar @keys; $j++) {
	    my $key = "$keys[$i] $keys[$j]";
	    my $vi = $typeH->{$keys[$i]};
	    my $vj = $typeH->{$keys[$j]};
	    my $value = "$vi vs $vj";
#print p("$key----------$value");
	    #output
  	    push(@$keyPairsARef, $key); 
  	    $labelPairsHRef->{$key} = "$value"; 
  	    push(@$labelPairsARef, $value); 
    	}
    }
}

#retrieves type 1 hash files
#comma separated files
sub fetchValueKeys {
    my ($val, $hRef) = @_;

    my $keys = ''; 
    foreach(sort keys %$hRef) {
	my $key = $_;
	my $value = $hRef->{$key};
	$keys .= ("$key,") if ($val eq $value); 
    }

    #get rid of the last comma 
    #two times chop
    chop $keys;
 
    return $keys;
}

sub runR {
    my ($Rexec, $Rcode, $Rargs, $RlogFN) = @_;
    print "<br>$Rexec < $Rcode --args $Rargs > $RlogFN<br>" if ($verbose);
    system("$Rexec < $Rcode --args $Rargs > $RlogFN");
}

sub renameColumn {
    my ($type, $name) = @_;
    my $columnName = renameFile('',$type,$name);
    $columnName =~ s/CEL$//;
    return $columnName;
}

sub renameFile {
    my ($normDir, $type, $name) = @_;

    #drop nonWord characters
    $name =~ s/[\W]//gi;

    return ($normDir . "X" . $type . "_" . $name);
}

sub formJpegFileName { 
    my ($dir, $file) = @_;
    return ($dir . $file. '.jpeg');
}

sub getType {
    my ($type) = @_;

    $type =~ s/[ \b\s]/_/g;
    return $type;
}

sub openPermissions {
    my ($dir) = @_;
    system("chmod 777 $dir; ");
}


#Package return value
############
1;
############
