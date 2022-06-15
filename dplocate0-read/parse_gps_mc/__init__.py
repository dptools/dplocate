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
    argparser = ap.ArgumentParser('parse_gps_mc Pipeline for Beiwe GPS')

    # Input and output parameters
    argparser.add_argument('--read-dir',
        help='Path to the input directory', required=True)
    argparser.add_argument('--output-dir',
        help='Path to the output directory', required=True)
    argparser.add_argument('--matlab-dir')
    argparser.add_argument('--extension')
    return argparser

def main(args):
    # expand any ~/ in the directories
    read_dir = os.path.expanduser(args.read_dir)
    output_dir = os.path.expanduser(args.output_dir)

    # perform sanity checks for inputs
    read_dir = check_input(read_dir)
    output_dir = check_output(output_dir)
    output_log=check_output2(os.path.join(output_dir,'gps_dash2'))
    if read_dir is None or output_dir is None:
        return

    # Check extension
    ext = args.extension
    if ext in ['csv', 'csv.lock']:
        ext = '.' + ext
    elif ext in ['.csv', '.csv.lock']:
        ext = ext
    else:
        logger.error('The extension provided is not compatible with this script.')
        sys.exit(1)

    # logger output
    fh = logging.FileHandler(os.path.join(output_log, 'parse_gps_mc.log'))
    logger.addHandler(fh)

    # run MATLAB
    run_matlab(read_dir, output_dir, args.extension, args.matlab_dir)

# Run MATLAB
def run_matlab(input_dir, output_dir, extension, matlab_dir):
    try:
        matlab_path = "addpath('{matlab_dir}');".format(matlab_dir=matlab_dir)
        sub_cmd = "parse_gps_mc('{INPUT_DIR}','{OUTPUT_DIR}','{EXTENSION}','{matlab_dir}')".format(OUTPUT_DIR=output_dir,
            INPUT_DIR=input_dir, EXTENSION=extension, matlab_dir=matlab_dir)
        
        sub_cmd = wrap_matlab(sub_cmd)

        if matlab_dir:
            sub_cmd = matlab_path + sub_cmd

        cmd = ['matlab', '-nojvm', '-nodisplay', '-nosplash', '-r', sub_cmd]
        sp.check_call(cmd, stderr=sp.STDOUT)

    except Exception as e:
        logger.error(e)

def wrap_matlab(cmd):
    return 'try; {0}; catch; err = lasterror; disp(err.message); quit(1); end; quit();'.format(cmd)

# Exit program if the input directory does not exist.
def check_input(read_dir):
    if os.path.exists(read_dir):
        return read_dir
    else:
        logger.error('%s does not exist.' % read_dir)
        return None

# Exit program if the output directory does not exist.
def check_output(output_dir):
    if os.path.exists(output_dir):
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

# Build the subdirectory if the output subdirectory does not exist.
def check_output2(output_dir):
    if os.path.exists(output_dir):
        return output_dir
    else:
        try:
            os.mkdir(output_dir)
            return output_dir
        except Exception as e:
            logger.error('Could not create %s' % output_dir)
            return None


if __name__ == '__main__':
    parser = parse_args()
    args = parser.parse_args()
    main(args)
