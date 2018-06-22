# read all final matrices
m1 = as.matrix( read.table(file="matrices/SBCC_nr_subpops_matrix_1.txt", header=F) )
m2 = as.matrix( read.table(file="matrices/SBCC_nr_subpops_matrix_2.txt", header=F) )
m3 = as.matrix( read.table(file="matrices/SBCC_nr_subpops_matrix_3.txt", header=F) )
m4 = as.matrix( read.table(file="matrices/SBCC_nr_subpops_matrix_4.txt", header=F) )
m5 = as.matrix( read.table(file="matrices/SBCC_nr_subpops_matrix_5.txt", header=F) )
m6 = as.matrix( read.table(file="matrices/SBCC_nr_subpops_matrix_6.txt", header=F) )
m7 = as.matrix( read.table(file="matrices/SBCC_nr_subpops_matrix_7.txt", header=F) )
m8 = as.matrix( read.table(file="matrices/SBCC_nr_subpops_matrix_8.txt", header=F) )
m9 = as.matrix( read.table(file="matrices/SBCC_nr_subpops_matrix_9.txt", header=F) )
m10 = as.matrix( read.table(file="matrices/SBCC_nr_subpops_matrix_10.txt", header=F) )

# make a list of matrices and get mean as explained in:
# http://stackoverflow.com/questions/18558156/mean-of-each-element-of-a-list-of-matrices
mat_list = list( m1, m2, m3, m4, m5, m6, m7, m8, m9, m10 )
mean_mat = apply(simplify2array(mat_list), c(1,2), mean)

# write resulting mean cov matrix
write.table(mean_mat,file="matrices/SBCC_nr_subpops_matrix_mean.txt",
            sep="\t",row.names=F,col.names=F,quote=F)
