#!/usr/bin/env perl 
use strict;
use warnings;

die "# usage: $0 <SNP.tsv> <sample order file> <outfile.tsv> [optional marker list]\n" if(!$ARGV[1]);

my ($SNPtsvfile,$order_file,$outfile,$marker_list_file) = @ARGV;

my @CALLS = qw( A C G T );
my $MAXMISSINGRATIO = 0.1; # 10% 
my $MISSINGVALUE    = '-999';

our %degen_htz = ( 
'S','CG','W','AT',
'Y','CT','R','AG',
'M','AC','K','GT',
);

warn "# MAXMISSINGRATIO=$MAXMISSINGRATIO MISSINGVALUE=$MISSINGVALUE\n";

my $n_of_valid_markers = 0;
my $n_of_valid_columns = 0;
my (%sample_order,%valid_column,@sorted_samples,%order2column,%list);
my ($sample,$col,$call,$marker,$allele1,$allele2,$MAF);

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

# 3) parse SNPs and print them in STRUCTURE format

open(OUT,'>',$outfile) || die "# cannot create $outfile\n";

open(SNP,'<',$SNPtsvfile) || die "# cannot read $SNPtsvfile\n";
while(<SNP>)
{
  #marker  SBCC001 SBCC002 SBCC003 SBCC004 ...
  #3255789|F|0 G G G missing missing ...
  chomp;
  my @data = split(/\t/,$_);

  if($data[0] eq 'marker')
  {
    print OUT "marker";
    foreach $col (1 .. $#data)
    {
      $sample = $data[$col];
      if(!$sample_order{$sample})
      {
        warn "# skip sample $sample\n";
        next;
      }

      print OUT "\t$sample";

      # save valid columns and order
      $valid_column{$col}=1; 
      $order2column{$sample} = $col;
      $n_of_valid_columns++;
    }
    print OUT "\n";

    warn "# total valid samples: $n_of_valid_columns\n";
  
    # headings
    warn "#\tsnpname\t allele1 allele2 missing MAF\n";
    # double check
    #foreach $sample (@sorted_samples){ $col = $order2column{$sample}; print "$sample $col\n"; }  exit;
  }
  else
  {
    $marker = $data[0]; #print "$marker\n";

    #next if($marker ne 'SCRI_RS_159201'); # debug

    # skip markers not in %list if required
    next if(%list && !$list{$marker});

    my (%freq,%missing,%obs,$genotypes);
    ($allele1,$allele2) = ('','');

    $genotypes = $data[0];  

    foreach $col (1 .. $#data)
    {
      next if(!$valid_column{$col});

      $genotypes .= "\t$data[$col]";

      $call = $data[$col];
      if($call eq 'missing' || $call =~ /-/)
      { 
        $missing{$col}=1;
      }
      else
      {
        $call=uc($call); # standard
        $freq{$call}{$col}=1; #print "$col $call\n";
        $obs{$call}++;
      }
    }

    # skip fixed or [3,4]-allelic loci
    next if(scalar(keys(%freq)) != 2);

    # skip SNPs with too many missing data
    next if( (scalar(keys(%missing))/$n_of_valid_columns) > $MAXMISSINGRATIO);

    # define alleles 1 & 2 
    foreach $call (sort keys(%freq))
    {
      if($allele1 eq ''){ $allele1 = $call }
      elsif($allele2 eq ''){ $allele2 = $call; last }
    }
  
    # skip SNPs with htzg calls that amount > 2 bases
    next if( ($degen_htz{$allele1} || $degen_htz{$allele2}) || 
          ($degen_htz{$allele1} && $degen_htz{$allele1} !~ /$allele2/) ||
          ($degen_htz{$allele2} && $degen_htz{$allele2} !~ /$allele1/) );

    # change missing data strings
    $genotypes =~ s/\-/$MISSINGVALUE/g;
    $genotypes =~ s/missing/$MISSINGVALUE/g;

    print OUT "$genotypes\n";

    $n_of_valid_markers++;
    
    $MAF = $obs{$allele2};
    if($obs{$allele1} < $MAF){ $MAF = $obs{$allele1} }

    printf(STDERR "%d\t%s\t%s\t%s\t%d\t%1.3f\n",
      $n_of_valid_markers,$marker,$allele1,$allele2,
      scalar(keys(%missing)), 
      $MAF/(scalar(@sorted_samples) - scalar(keys(%missing))));
  }
}
close(SNP);

close(OUT);

warn "# total valid markers=$n_of_valid_markers\n";
