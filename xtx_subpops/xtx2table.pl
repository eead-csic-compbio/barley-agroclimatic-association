#!/usr/bin/env perl
use strict;

die "# usage: $0 <XtX file> <SNP order file>\n" if(!$ARGV[1]);

my $PREFIX = 'snp_batch';

my ($BFfile,$snp_order_file,$keep_order) = @ARGV;

my $n_of_variables = 0;
my ($varname,$var,$snpfilename,$SNP,$SNPname,$BF,$spearman,$pearson);
my (%variable_order,%SNP_fullname);

# 1) read SNP order file
open(SNPORDER,'<',$snp_order_file) || die "# cannot read $snp_order_file\n";
while(<SNPORDER>)
{
  chomp;
  ($SNP,$SNPname) = split(/\t/,$_);
  $SNP_fullname{$SNP} = $SNPname;
  #print "$SNP $SNPname\n";
}
close(SNPORDER); 


# 2) parse XtXs
print "SNPidentifier\tXtX\n";

if($BFfile =~ /\.gz$/) # GZIP compressed
{
  if(!open(BF,"gzip -dc $BFfile |"))
  {
    die "# cannot read GZIP compressed $BFfile $!, please check gzip is installed\n";
  }
}
else
{ 
  open(BF,'<',$BFfile) || die "# cannot read $BFfile\n";
}
  
while(<BF>)
{
  #VrnH3.tsv 1.1909e+00  
  chomp;
  my @data = split(/\t/,$_);
  ($snpfilename,$BF) = @data[0,1];
  if($snpfilename =~ m/$PREFIX(\d+)/)
  {
    $SNP = $1 + 0; # as number
    $SNPname = $SNP_fullname{$SNP} || $SNP;
  
    printf("%s\t%1.2f\n",$SNPname,$BF);
  }
}
close(BF);

