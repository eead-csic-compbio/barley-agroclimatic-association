/*
    LFMM, file: main_LFMM.c
    Copyright (C) 2012 Eric Frichot

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "../LFMM/LFMM.h"
#include "../LFMM/register_lfmm.h"
#include "../LFMM/print_lfmm.h"
#include "../io/io_tools.h"
#include "../matrix/matrix.h"

int main(int argc, char *argv[])
{
        // parameters allocation
        lfmm_param *param = (lfmm_param *) calloc(1, sizeof(lfmm_param));

        // Parameters initialization
        init_param_lfmm(param);

        // print
        print_head_lfmm();
        print_options(argc, argv);

        // analyse the command line and fill param
        analyse_param_lfmm(argc, argv, param);

        // run function
        LFMM(param);

        // free memory 
        free_param_lfmm(param);
        free(param);

        return 0;

}
