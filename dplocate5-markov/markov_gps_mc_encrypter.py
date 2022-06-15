#!/usr/bin/env python

import os
import sys
import cryptease as enc
import argparse as ap

def main():
    argparser = ap.ArgumentParser('Decrypter')
    argparser.add_argument('--input',
        help='Unlocked file path',
        required=True)
    argparser.add_argument('--output',
        help='Locked file path',
        required=True)

    args = argparser.parse_args()
    
    lst = args.input
    passw = os.environ['BEIWE_STUDY_PASSCODE']

    try:
        with open(lst,'rb') as fp:
            key = enc.kdf(passw)
            enc.encrypt(fp, key, filename=args.output)
    except Exception as e:
        print(e)

if __name__ == '__main__':
    main()