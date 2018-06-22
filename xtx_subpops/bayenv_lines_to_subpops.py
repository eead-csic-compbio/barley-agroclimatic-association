#!/usr/bin/env python
# -*- coding: utf-8 -*-
# CPCantalapiedra 2017

import sys, traceback

subpops_filename = sys.argv[1]
order_filename = sys.argv[2]
bayenv_filename = sys.argv[3]
show_count_errors = True if sys.argv[4] == "show" else False

####### functions
#

#### Global

subpops_dict = {} # line --> subpop
subpops_set = None # subpops
subpops_counts = {} # subpop --> num_lines
order_dict = {} # line --> column
counts_list = [] # [allele_a,allele_b] --> counts

########## First, lines subpopulations and order
##########

# Subpopulations
subpops_file = open(subpops_filename, 'r')

num_lines_read = 0
try:
    sys.stderr.write("Reading lines-subpopulations file...\n")
    
    for line in subpops_file:
        num_lines_read += 1
        line_data = line.strip().split("\t")
        
        line_id = line_data[0]
        line_subpop = line_data[1]
        
        if line_id in subpops_dict:
            if line_subpop != subpops_dict[line_id]:
                raise Exception("Ambiguous subpopulation asignation for line "+
                                line_id)
            # else: they are equal. Maybe create a warning?
        else:
            subpops_dict[line_id] = line_subpop
    
except Exception as e:
    traceback.print_exc()
    raise e
finally:
    subpops_file.close()

subpops_set = set(subpops_dict.values())

sys.stderr.write("Read "+str(num_lines_read)+" lines in "+
                 str(len(subpops_set))+" subpops.\n")

# num of lines in each subpop
subpops_list = sorted(subpops_set)
for subpop in subpops_list:
    num_lines_subpop = [x for x in subpops_dict if subpops_dict[x] == subpop]
    num_lines_subpop = len(num_lines_subpop)
    sys.stderr.write("\t "+str(num_lines_subpop)+" in subpop "+subpop+"\n")
    subpops_counts[subpop] = num_lines_subpop

# Lines order
order_file = open(order_filename, 'r')

num_lines_read = 0
try:
    sys.stderr.write("Reading markers order file...\n")
    
    for line in order_file:
        num_lines_read += 1
        line_data = line.strip().split("\t")
        
        line_id = line_data[0]
        line_order = num_lines_read
        
        if line_order in order_dict:
            if line_id != order_dict[line_order]:
                raise Exception("Ambiguous order asignation for line order "+
                                line_order)
            # else: the same order. Maybe create a warning?
        else:
            order_dict[line_order] = line_id
    
except Exception as e:
    traceback.print_exc()
    raise e
finally:
    order_file.close()

sys.stderr.write("Read "+str(num_lines_read)+" lines in order file.\n")

###### Read bayenv individual lines file
## to create the bayenv subpopulations file

bayenv_file = open(bayenv_filename, 'r')

num_lines_read = 0
prev_subpops_counts = None
subpops_counts_error = {}
try:
    sys.stderr.write("Reading markers order file...\n")
    
    for line in bayenv_file:
        num_lines_read += 1
        line_data = line.strip().split("\t")
        
        current_subpops_counts = {}
        for i, field in enumerate(line_data):
            column = i+1
            genotype = order_dict[column]
            subpop = subpops_dict[genotype]
            if subpop in current_subpops_counts:
                current_subpops_counts[subpop] += int(field)
            else:
                current_subpops_counts[subpop] = int(field)
        
        if num_lines_read % 2 == 0:
            count_error = False
            for subpop in subpops_set:
                subpop_count = prev_subpops_counts[subpop]+current_subpops_counts[subpop]
                if subpop_count != subpops_counts[subpop]:
                    #print prev_subpops_counts
                    #print current_subpops_counts
                    #print ""
                    count_error = True
                    if num_lines_read in subpops_counts_error:
                        subpops_counts_error[num_lines_read].append(subpop)
                    else:
                        subpops_counts_error[num_lines_read] = [subpop]
            
            if show_count_errors or not count_error:
                counts_list.append([prev_subpops_counts, current_subpops_counts])
            #print prev_subpops_counts
            #print current_subpops_counts
            #print ""
        
        prev_subpops_counts = current_subpops_counts
    
except Exception as e:
    traceback.print_exc()
    raise e
finally:
    bayenv_file.close()

sys.stderr.write("Read "+str(num_lines_read/2)+" markers in bayenv file.\n")
sys.stderr.write("Num markers with error in subpop counts "+
                 str(len(subpops_counts_error))+"\n")

## Output lines

num_subpops = len(subpops_set)

sys.stderr.write("Subpopulations list (sorted): "+",".join(subpops_list)+"\n")
for count_data in counts_list:
    allele_a = count_data[0]
    allele_b = count_data[1]
    for i, subpop in enumerate(subpops_list):
        if i == num_subpops-1:
            sys.stdout.write(str(allele_a[subpop]))
        else:
            sys.stdout.write(str(allele_a[subpop])+"\t")
    
    sys.stdout.write("\n")
    
    for i, subpop in enumerate(subpops_list):
        if i == num_subpops-1:
            sys.stdout.write(str(allele_b[subpop]))
        else:
            sys.stdout.write(str(allele_b[subpop])+"\t")
    
    sys.stdout.write("\n")


##
sys.stderr.write("Finished.\n")

## END