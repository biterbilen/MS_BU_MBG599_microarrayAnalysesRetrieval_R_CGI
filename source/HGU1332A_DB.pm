#class HGU1332A_DB
package HGU1332A_DB;

use strict;
use CGI qw/:standard :html3 :cgi-lib/;
use CGI::Carp qw(fatalsToBrowser);

#constructor
sub new {
    my ($class) = @_;
    my $self = {
        _dbName 	=> "microarray", 	
	_dbUserName	=> "oncogene", 		
	_dbUserPass	=> "biterb", 		
	_dbConSt	=> "dbi:mysql:host=localhost:database=",
    };
    $self->{_dbConSt}      .= $self->{_dbName};
    bless $self, $class;
    return $self;
}

sub formTableName{
    my($self, $key) = @_;
    return "$self->{_tag}$key$self->{_aID}";
}

sub dropTable {
    my ($self, $tableN) = @_;

    my $dropSt = getDropStmt($tableN);
#print p("$dropSt;");
    my $dbh = $self->connect;

    #drop the old data if a table exits
    $dbh->do($dropSt) or die("Can't execute $dropSt: $dbh->errstr\n");
    $self->disconnect($dbh);
}

sub formNumberTab {
    my ($self, $entryRef, $decPlaces) = @_;
    my $ret = '';
    foreach(@$entryRef)
    {
	$ret = sprintf("%s%.$decPlaces"."f\t", $ret, $_)
    }
    $ret =~ s/\t$//;
    return $ret;
}

#connect the database
sub connect {
    my ($self) = @_;
    my $dbh = DBI->connect($self->{_dbConSt}, $self->{_dbUserName}, $self->{_dbUserPass}) or
                die "The $self->{_dbName} database could not be connected";
    return $dbh;
}

sub disconnect {
    my ($self, $dbh) = @_;
    $dbh->disconnect;
}

sub print {
    my ($self) = @_;

    #print HGU1332A_DB info
    printf( "\nPRINT\n");
    printf( "dbName:\t%s\n", $self->{_dbName});
    printf( "dbUserName:\t%s\n", $self->{_dbUserName});
    printf( "dbUserPass:\t%s\n", $self->{_dbUserPass});
    printf( "dbConSt:\t%s\n", $self->{_dbConSt});
    printf( "dbInsSt:\t%s\n", $self->{_dbInsSt});
    printf( "dbDelSt:\t%s\n", $self->{_dbDelSt});
    printf( "dbCreSt:\t%s\n", $self->{_dbCreSt});
    printf( "dbDropStmt:\t%s\n", $self->{_dbDropSt});
}

#############################
1;
#############################
