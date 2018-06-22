# BAYENV #

[Here](https://bitbucket.org/tguenther/bayenv2_public/src) you can find executables, a manual and example files for bayenv and bayenv2.

When using bayenv please make sure that you have recently downloaded the program, to avoid old bugs. Please email Torsten (torsten.guenther 'at' ebc.uu.se) for questions or access to the code. 

**Please note that only the Linux 64bit version is updated regularly. The versions for Linux 32bit and MacOS were tested initially but (due to a lack of suitable machines), we do not provide updated executables at the moment. Please ask for the source code to compile it on your machine if you want to make sure that your version is up to date.**

## Description ##

Loci involved in local adaptation can potentially be identified by an unusual correlation between allele frequencies and important ecological variables, or by extreme allele frequency differences between geographic regions. However, such comparisons are complicated by differences in sample sizes and the neutral correlation of allele frequencies across populations due to shared history and gene flow. To overcome these difficulties, we have developed a Bayesian method that estimates the empirical pattern of covariance in allele frequencies between populations from a set of markers, and then uses this as a null model for a test at individual SNPs. Graham developed this method in collaboration with David Witonsky, Anna Di Rienzo and Jonathan Pritchard. The method is described in a paper in Genetics:

Coop G., Witonsky D., Di Rienzo A., Pritchard J.K. [Using Environmental Correlations to Identify Loci Underlying Local Adaptation.](http://www.genetics.org/content/185/4/1411.abstract) Genetics. 2010

The method was further developed by Torsten Günther and Graham Coop. The newest version of the method is called Bayenv 2, and it maintains the full functionality of the original Bayenv.

Günther T., Coop G. [Robust identification of local adaptation from allele frequencies.](http://www.genetics.org/content/195/1/205) Genetics. 2013

## Recent updates ##

Apr 22 2015

* Issue with file name length fixed

Feb 6 2015

* moved to Bitbucket
* updated manual
* minor bugfixes
* added a bash script which loops through all SNPs in a file
