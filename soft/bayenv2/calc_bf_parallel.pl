#!/usr/bin/env perl
# Perl script to compute BFs for a (large) SNP file in parallel and then merge the result
# Bruno Contreras Moreira EEAD-CSIC Oct2016

use strict;
use Benchmark;
use POSIX;
use FindBin '$Bin';
use lib "$Bin/";
use ForkManager;

my $VERBOSE = 0;
my $BAYENVEXE = "$Bin/bayenv2";

# standard linux utilities
my $SPLITEXE  = '/usr/bin/split';
my $WCEXE     = '/usr/bin/wc';
my $CATEXE    = '/bin/cat';

my ($n_of_cores,$raw_command,$batch_command) = (1,'');
my ($outfileOK,$n_of_snps,$input_snp_file,$output_file) = (0,0,'','');
my (@batches,@snp_files,@outfiles,$snp_file,$tmp_output_file);

if(!$ARGV[1])
{
  print "\nUsage: perl $0 <number of processors/cores> <bayenv2 command>\n\n";
  print "<number of processors/cores> : while 1 is accepted, at least 2 should be requested\n";
  print "<bayenv2 command> : is the explicit command that you would run in your terminal\n\n";
  die "Example: bayenv2 -t -i input.tsv -p 20 -e env.tsv -n 87 -m matrix.txt -k 100000 -r 12345 -c -o test.env
\n\n";
}
else ## parse command-line arguments
{
  $n_of_cores = shift(@ARGV);
  if($n_of_cores < 0){ $n_of_cores = 1 }

  $raw_command = join(' ',@ARGV);
  
  if($raw_command !~ m/-t /)
  {
    die "# ERROR: command must include -t\n"
  }

  if($raw_command =~ m/-i (\S+)/){ $input_snp_file = $1 }
  
  if($raw_command =~ m/-o (\S+)/){ $output_file = $1 }
  
  if($input_snp_file eq '' || $output_file eq ''){ die "# ERROR: command must include input & output files \n" }
  
  
  if($raw_command !~ m/-m (\S+)/)
  {
    die "# ERROR: command must include -m matrix\n"
  }
  elsif($raw_command !~ m/-e (\S+)/)
  {
    die "# ERROR: command must include -e file\n"
  }
  elsif($raw_command !~ m/-p (\d+)/)
  {
    die "# ERROR: command must include -p populations\n"
  }
  elsif($raw_command !~ m/-n (\S+)/)
  {
    die "# ERROR: command must include -n variables\n"
  }
  elsif($raw_command !~ m/-k (\d+)/)
  {
    die "# ERROR: command must include -k iterations\n"
  }
  elsif($raw_command !~ m/-r (\d+)/)
  {
    die "# ERROR: command must include -r seed\n"
  }

  print "# parameters: max number of processors=$n_of_cores \$VERBOSE=$VERBOSE\n";
  print "# raw command: $raw_command\n\n";
}

# track computing time
my $start_time = new Benchmark();

# split input SNP file in chunks of two lines
$n_of_snps = `$WCEXE -l $input_snp_file`;
$n_of_snps /= 2;

print "# total SNPs in $input_snp_file: $n_of_snps\n\n";

my $digits2split = ceil(log($n_of_snps)/log(10));

system("$SPLITEXE -l 2 -a $digits2split --numeric-suffixes $input_snp_file snp_batch");

opendir(PWD,"./");
@snp_files = sort grep{/snp_batch\d+/} readdir(PWD);
closedir(PWD);

# prepare a command for each batch/SNP
foreach $snp_file (@snp_files)
{
  $batch_command = $raw_command;
  $batch_command =~ s/$input_snp_file/$snp_file/;
  $batch_command =~ s/$output_file/$snp_file/;
  $batch_command =~ s/\S*bayenv2 /$BAYENVEXE /;
  $tmp_output_file = "$snp_file.bf";
  print "$batch_command\n" if($VERBOSE);
  
  push(@batches,$batch_command);
  push(@outfiles,$tmp_output_file);
} 

# create requested number of threads
if($n_of_snps < $n_of_cores)
{
  $n_of_cores = $n_of_snps;
  print "# WARNING: using only $n_of_cores cores\n";
}
my $pm = ForkManager->new($n_of_cores);


## submit batch jobs to allocated threads
foreach $batch_command (@batches)
{
  $pm->start($batch_command) and next; # fork

  print "# running $batch_command in child process $$\n" if($VERBOSE);
  open(BATCHJOB,"$batch_command 2>&1 |");
  while(<BATCHJOB>)
  {
    if(/Error/ || /cannot/){ print; last }
    elsif($VERBOSE){ print }
  }
  close(BATCHJOB);

  $pm->finish(); # exit the child process
}

$pm->wait_all_children();

# overwrite output file 
unlink($output_file) if(-s $output_file);
 
# merge individual output files into a single output file and clean tmp files
foreach my $f (0 .. $#snp_files)
{
  $snp_file        = $snp_files[$f];
  $tmp_output_file = $outfiles[$f];
  $batch_command   = $batches[$f];
  
  if(!-s $tmp_output_file) 
  {
    #unlink($output_file) if(-e $output_file);
    warn "# ERROR : did not produce results file $tmp_output_file ,".
      " probably job failed: $batch_command\n";
  }
  else
  {
    print "# adding $tmp_output_file results to $output_file\n" if($VERBOSE);
    system("$CATEXE $tmp_output_file >> $output_file"); 

    # clean
    unlink($snp_file,$tmp_output_file,"$snp_file.freqs");
  }
}

my $end_time = new Benchmark();
print "\n# runtime: ".timestr(timediff($end_time,$start_time),'all')."\n";
