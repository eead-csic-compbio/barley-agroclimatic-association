#!/usr/bin/env perl
use strict;

die "# usage: $0 <BF file> <climate order file> [SNP order file (optional)] [bool: original order]\n" if(!$ARGV[1]);

my $PREFIX = 'snp_batch';

my ($BFfile,$order_file,$snp_order_file,$keep_order) = @ARGV;

my $n_of_variables = 0;
my ($varname,$var,$snpfilename,$SNP,$SNPname,$BF,$spearman,$pearson);
my (%variable_order,%SNP_fullname);

# 1) read real names of climate variables
open(ORDER,'<',$order_file) || die "# cannot read $order_file\n";
while(<ORDER>)
{
  $n_of_variables++;
  $varname = (split)[0];
  $variable_order{$n_of_variables} = $varname;
  #print "$n_of_variables $varname\n";
}
close(ORDER); 

# 1.1) try to read optional SNP order file
if(-s $snp_order_file)
{
  open(SNPORDER,'<',$snp_order_file) || die "# cannot read $snp_order_file\n";
  while(<SNPORDER>)
  {
    chomp;
    ($SNP,$SNPname) = split(/\t/,$_);
    $SNP_fullname{$SNP} = $SNPname;
    #print "$SNP $SNPname\n";
  }
  close(SNPORDER); 
}


# 2) parse BFs, Spearman's and Pearson's correlations
# From the manual:
# "The first column gives the name of SNPFILE followed by a column showing the Bayes factor (see above),
# a column showing Spearman rho and a column showing Pearson correlation coefficient. 
# If more than one environmental variables are used, additional column trios (BF, rho and r) are appended"

print "SNPidentifier\tvariable\tBF\trho_Spearman\n";

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
  #VrnH3.tsv 1.1909e+00  -6.6583e-02 -5.8913e-02 6.0319e-01  -2.0379e-02 -2.1083e-02 ...
  chomp;
  my @data = split(/\t/,$_);
  $snpfilename = shift(@data);# print "$snpfilename $n_of_variables $#data\n";

  # only BFs computed
  if($n_of_variables==$#data+1)
  {
    # nothing done
  }
  elsif($n_of_variables*3==$#data+1) # BF, rho and r
  {
    my (%BFtable,@order);
    $var = 0;
    while (@data) 
    {
      $var++;
      ($BF,$spearman,$pearson) = splice(@data,0,3);
      $varname = $snpfilename.':'.$variable_order{$var};
      $BFtable{$varname} = [ $BF , $spearman ];
      #printf("%s\t%1.3f\t%1.3f\n",$variable_order{$var},$BF,$spearman);
      if($keep_order)
      {
        push(@order,$varname)
      }
    } 

    # sort variables if required
    if(!$keep_order)
    {
      @order = sort {
      $BFtable{$b}->[0] <=> $BFtable{$a}->[0] ||
      $BFtable{$b}->[1] <=> $BFtable{$a}->[1]
      } keys(%BFtable);
    }
    
    foreach $var (@order)
    {
      ($SNP,$varname) = split(/:/,$var);
      
      if($SNP =~ m/$PREFIX(\d+)/)
      {
        $SNP = $1 + 0; # as number
      }
      
      $SNPname = $SNP_fullname{$SNP} || $SNP;
    
      printf("%s\t%s\t%1.3f\t%1.3f\n",
        $SNPname,$varname,$BFtable{$var}->[0],$BFtable{$var}->[1]);
    }
  }
}
close(BF);

