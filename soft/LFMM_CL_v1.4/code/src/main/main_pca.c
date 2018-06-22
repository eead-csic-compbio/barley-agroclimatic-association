/*
 *     pca, file: main_pca.c
 *     Copyright (C) 2013 Eric Frichot
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

#include "../pca/pca.h"
#include "../pca/register_pca.h"

int main(int argc, char *argv[])
{
        int n = 0;              // number of individuals
        int L = 0;              // number of loci
        int K = 0;              // number of PCs
        int s = 0;              // scale parameter
        int c = 0;              // center parameter
        char input_file[512];   // input file
        char output_eva_file[512] = ""; // output eigenvalues file
        char output_eve_file[512] = ""; // output eigenvectors file
        char output_sdev_file[512] = "";        // output sdev file
        char output_x_file[512] = "";   // output x file

        // analyze command-line
        analyse_param_pca(argc, argv, input_file, output_eva_file,
                          output_eve_file, output_sdev_file, output_x_file,
                          &K, &c, &s);

        // run function
        pca(input_file, output_eva_file, output_eve_file,
            output_sdev_file, output_x_file, &n, &L, &K, c, s);

        return 0;
}
