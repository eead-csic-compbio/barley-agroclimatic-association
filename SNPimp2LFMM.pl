#!/usr/bin/env perl
use strict;
use warnings;

# similar to SNP2LFMM.pl but for imputed biallelic data in states 0,1
# Input should contain no missing data 

die "# usage: $0 <SNP.tsv> <sample order file> <outfile.tsv> [optional marker list]\n" if(!$ARGV[1]);

my ($SNPtsvfile,$order_file,$outfile,$marker_list_file) = @ARGV;

my $MINAF = 0.05;


warn "# MAF=$MINAF\n";

my $n_of_valid_markers = 0;
my $n_of_valid_columns = 0;
my (%sample_order,%valid_column,@sorted_samples,%order2column,%list);
my ($sample,$col,$call,$marker,$allele1,$allele2,$MAF);
my $annotfile = $outfile;
$annotfile =~ s/\.tsv/.annot.tsv/;

# 1) read valid samples and record their order taken from ENVIRONFILE
open(ORDER,'<',$order_file) || die "# cannot read $order_file\n";
while(<ORDER>)
{
  $sample = (split)[0];
  $sample_order{$sample} = $.; #print "$sample $.\n";
  push(@sorted_samples,$sample);
}
close(ORDER);

printf(STDERR "# total samples in %s: %d\n",$order_file,scalar(@sorted_samples));

if($marker_list_file && -s $marker_list_file)
{
	open(LIST,'<',$marker_list_file);
	while(<LIST>)
	{
		$list{(split)[0]}=1;
	}
	close(LIST);

	printf(STDERR "# total markers in %s: %d\n",
		$marker_list_file,scalar(keys(%list)));
}

# 3) parse SNPs and print them in LFMM format

open(OUT,'>',$outfile) || die "# cannot create $outfile\n";

open(ANNOT,'>',$annotfile) || die "# cannot create $annotfile\n";

warn "# creating $annotfile\n";

open(SNP,'<',$SNPtsvfile) || die "# cannot read $SNPtsvfile\n";
while(<SNP>)
{
  #marker  SBCC001 SBCC002 SBCC003 SBCC004 ...
  #3255789|F|0 1 0 1 ...
  chomp;
  my @data = split(/\t/,$_);

  if($data[0] eq 'marker')
  {
    foreach $col (1 .. $#data)
    {
      $sample = $data[$col];
      if(!$sample_order{$sample})
      {
        warn "# skip sample $sample\n";
        next;
      }

      # save valid columns and order
      $valid_column{$col}=1; 
      $order2column{$sample} = $col;
      $n_of_valid_columns++;
    }

    warn "# total valid samples: $n_of_valid_columns\n";
  
    # headings
    warn "#\tsnpname\t allele1 allele2 other MAF\n";
  }
  else
  {
    $marker = $data[0]; #print "$marker\n";

    # skip markers not in %list if required
    next if(%list && !$list{$marker});

    #next if($marker ne '3256790|F|0'); # debugging

    my (%freq,%missing,%obs);
    ($allele1,$allele2) = ('','');

    foreach $col (1 .. $#data)
    {
      next if(!$valid_column{$col});

      $call = $data[$col];
      if($call != 1 && $call != 0)
      { 
        $missing{$col}=1;
      }
      else
      {
        $freq{$call}{$col}=1; 
        $obs{$call}++;
      }
    }

    # skip fixed or [3,4]-allelic loci
    next if(scalar(keys(%freq)) != 2);
    
    # define alleles 1 & 2 
    foreach $call (sort keys(%freq))
    {
      if($allele1 eq ''){ $allele1 = $call }
      elsif($allele2 eq ''){ $allele2 = $call; last }
    }
  
    # skip SNPs with low MAF
    $MAF = $obs{$allele2};
    if($obs{$allele1} < $MAF){ $MAF = $obs{$allele1} }
    
    #printf("# skip $marker (%1.3f [%d / %d - %d] < %f)\n",
    #    ($MAF/(scalar(@sorted_samples) - scalar(keys(%missing)))),
    #    $MAF, scalar(@sorted_samples), scalar(keys(%missing)),
    #    $MINAF);
    
    next if( ($MAF/(scalar(@sorted_samples) - scalar(keys(%missing)))) <  $MINAF );
    

    # print alleles in a string
    foreach $sample (@sorted_samples)
    {
      $col = $order2column{$sample};

      if($freq{$allele1}{$col}){ print OUT "1\t" }
      elsif($freq{$allele2}{$col}){ print OUT "2\t" }
      else{ print OUT "0\t" }
    }
    print OUT "\n";
    
    print ANNOT "$n_of_valid_markers\t$marker\n";
    
    $n_of_valid_markers++;

    printf(STDERR "%d\t%s\t%s\t%s\t%d\t%1.3f\n",
      $n_of_valid_markers,$marker,$allele1,$allele2,
      scalar(keys(%missing)), 
      $MAF/(scalar(@sorted_samples) - scalar(keys(%missing))));
  }
}
close(SNP);

close(OUT);

close(ANNOT);

warn "# total valid markers=$n_of_valid_markers\n";
