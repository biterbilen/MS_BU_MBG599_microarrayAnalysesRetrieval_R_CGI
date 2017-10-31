#class HGU1332A_Html
package HGU1332A_Html;

use CGI qw/:standard :html3/;
use CGI::Carp qw(fatalsToBrowser);
use strict;
use warnings;

#constructor
sub new {
    my ($class) = @_;

    my $self = {
	_author	 => 'Biter Bilen',
	_styles	 => undef,
	_title 	 => undef,
	_target	 => undef,
	_jscript => undef,
	_pageTitle => undef
    };
    $self->{_styles} = <<_STYLES;
	<!-- 	
   	.style1 {
	   	font-size: 14px; #font-family: Arial, Helvetica, sans-serif; 
    	}
    	.style2 {
      	color: #326495;
    	}    	
    	.style3 {
      	color: #666666;
    	}    	
    	.style4 {
    		font-family: "Courier New", Courier, mono;
    	}
    	.style5 {
		   border-bottom: font-weight: 400; color: darkgrey; position: relative;
    	}
    	.style6 {
		   font-size: 12px;
    	}
    	.style7 {
			border-style: 1;
		}	
	-->
_STYLES
    bless $self, $class;
    return $self;
}

#accessor method for u1332A_Html, title 
sub _title
{
    my ( $self, $title) = @_;
    $self->{_title} = $title if defined($title);
    return $self->{_title};
}

#accessor method for u1332A_Html, target
sub _target
{
    my ( $self, $target) = @_;
    $self->{_target} = $target if defined($target);
    return $self->{_target};
}

#accessor method for u1332A_Html, jscript
sub _jscript
{
    my ( $self, $script) = @_;
    $self->{_script} = $script if defined($script);
    return $self->{_script};
}

#accessor method for u1332A_Html, pageTitle
sub _pageTitle
{
    my ( $self, $pageTitle) = @_;
    $self->{_pageTitle} = $pageTitle if defined($pageTitle);
    return $self->{_pageTitle};
}

sub print 
{
    my ($self) = @_;

    #print u1332A_Html info
print '<div>';
    print ("u1332A_Html<br>");
    printf( "title:\t%s\n", $self->{_title});
    printf( "target:\t%s\n", $self->{_target});
    printf( "jscript:\t%s\n", $self->{_jscript});
    printf( "style:\t%s\n", $self->{_style});
    printf( "pageTitle:\t%s\n", $self->{_pageTitle});
print '</div>';

}

sub printU1332A_Header
{
    my ($self) = @_;
    print	
	header(),
	start_html(-title 	=> $self->{_title},
		-script	=> $self->{_jscript},
              	-base	=> 'true',
              	-target	=> $self->{_target},
              	-meta=>{'http-equiv' 	=>'Content-Type',
			'content'	=>'text/html',
			'author'	=>$self->{_author}},
              	-style=>{'code' => $self->{_style}});
}

sub printU1332A_Footer
{
    my($self) = @_;
    print end_html;
}

sub printU1332A_PageTitle
{
    my ($self) = @_;
    print
	'<div align="justify" class="style1 style2">',
	h1($self->{_pageTitle}),
	hr,		
	'</div>';
}		

sub printU1332A_Links
{
    my ($self) = @_;
    my $links = p(b(
			"::" . a({-href=>"degGroupsData.cgi", -target=>"_parent"}, 'DEG Groups Data Analysis') . 
			"::" . a({-href=>"wholeData.cgi", -target=>"_parent"}, 'Whole Data Analysis') . 
			"::" . a({-href=>"merge.cgi", -target=>"_parent"}, 'Merge DEG Groups') . 
			"::"
			));
    print
	'<div align="right" class="style1">',
	$links,
	'</div>';
}


##########################################################
#private functions
##########################################################

#Package return value
############
1;
############
