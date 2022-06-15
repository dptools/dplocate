#!/usr/bin/env python

###########################################################
###########################################################
###### Originally written by Habiballah Rahimi Eichi ######
###########################################################
###########################################################

import os
import sys
import argparse as ap
import logging
import subprocess as sp

logger = logging.getLogger(os.path.basename(__file__))
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def parse_args():
    argparser = ap.ArgumentParser('process_gps Pipeline for Beiwe GPS')

    # Input and output parameters
    argparser.add_argument('--read-dir',
        help='Path to the input directory', required=True)
    argparser.add_argument('--output-dir',
        help='Path to the output directory', required=True)
    argparser.add_argument('--matlab-dir')
    argparser.add_argument('--date-from')
    argparser.add_argument('--study',
        help='Study name. Required. Please provide one value.',
        required=True)
    argparser.add_argument('--subject',
        help='Subject ID',
        required=True)
    argparser.add_argument('--day-from',
        help='Output day from. (optional; Default: 1)',
        type = int, default = 1)
    argparser.add_argument('--day-to',
        help='Output day to. (optional; Default: 250)',
        type = int, default = 250)
    return argparser

def main(args):
    # expand any ~/ in the directories
    read_dir = os.path.expanduser(args.read_dir)
    output_dir = os.path.expanduser(args.output_dir)

    # perform sanity checks for inputs
    read_dir = check_input(read_dir)
    output_dir = check_output(output_dir)
    output_log=check_output(os.path.join(output_dir,'gps_dash2'))
    if read_dir is None or output_dir is None:
        return

    # logger output
    fh = logging.FileHandler(os.path.join(output_log, 'process_gps.log'))
    logger.addHandler(fh)

    # run MATLAB
    input_file = os.path.join(read_dir, 'gps_dash2/dash.mat.lock')
    if not os.path.exists(input_file):
        logger.error('The input file %s does not exist. Exiting.' % input_file)
        return

    run_matlab(input_file, output_dir, args.date_from, 
        args.day_from, args.day_to, args.study, args.subject, args.matlab_dir)

# Run MATLAB
def run_matlab(input_file, output_dir, date_from, day_from, day_to, study, subject, matlab_dir):
    try:
        matlab_path = "addpath('{matlab_dir}');".format(matlab_dir=matlab_dir)
        sub_cmd = "process_gps_mc('{ST}','{SB}','{C}','{DF}','{DT}','{I}','{O}','{M}')".format(ST=study,
            SB=subject,C=date_from,DF=day_from,DT=day_to,
            I=input_file, O=output_dir,M=matlab_dir)
        
        sub_cmd = wrap_matlab(sub_cmd)

        if matlab_dir:
            sub_cmd = matlab_path + sub_cmd

        cmd = ['matlab', '-nodisplay', '-nosplash', '-r', sub_cmd]
        sp.check_call(cmd, stderr=sp.STDOUT)

    except Exception as e:
        logger.error(e)

def wrap_matlab(cmd):
    return 'try; {0}; catch; err = lasterror; disp(err.message); quit(1); end; quit();'.format(cmd)

# Exit program if the input directory does not exist.
def check_input(read_dir):
    if os.path.exists(read_dir):
        read_dir = os.path.join(read_dir)
        if os.path.exists(read_dir):
            return read_dir
        else:
            logger.error('%s does not exist.' % read_dir)
            return None
    else:
        logger.error('%s does not exist.' % read_dir)
        return None

# Exit program if the output directory does not exist.
def check_output(output_dir):
    if os.path.exists(output_dir):
        output_dir = os.path.join(output_dir)
        if os.path.exists(output_dir):
            return output_dir
        else:
            try:
                os.mkdir(output_dir)
                return output_dir
            except Exception as e:
                logger.error('Could not create %s' % output_dir)
                return None
    else:
        logger.error('%s does not exist.' % output_dir)
        return None

if __name__ == '__main__':
    parser = parse_args()
    args = parser.parse_args()
    main(args)
