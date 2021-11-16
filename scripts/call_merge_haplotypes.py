#!/bin/env python


import collections
import gc
import gzip
import intervaltree
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd
import pysam
import subprocess
import sys
import re
from scipy import stats
import shutil
import tempfile

from Bio import SeqIO
import Bio.bgzf

import argparse
PIPELINE_DIR = os.path.dirname(os.path.abspath(__file__)).replace('scripts', '')
sys.path.append(PIPELINE_DIR)  # pavlib
sys.path.append(os.path.join(PIPELINE_DIR, 'dep', 'svpop'))  # svpoplib
sys.path.append(os.path.join(PIPELINE_DIR, 'dep'))  # kanapy

import pavlib
import svpoplib
import kanapy


parser = argparse.ArgumentParser()

parser.add_argument("--bed_var_h1", "-v", type=str, required=True)
parser.add_argument("--bed_var_h2", "-w", type=str, required=True)
parser.add_argument("--callable_h1", "-c", type=str, required=True)
parser.add_argument("--callable_h2", "-d", type=str, required=True)
parser.add_argument("--bed", "-o", type=str, required=True)
parser.add_argument("--ro_min", "-r", type=float, required=False, default=0.5)
parser.add_argument("--offset_max", "-f", type=int, required=False, default=200)
parser.add_argument("--merge_threads", "-m", type=int, required=False, default=12)
parser.add_argument("--vartype_svtype", "-s", type=str, required=True)
parser.add_argument("--chrom", "-x", nargs='*', type=str, required=True)

args = parser.parse_args()


if args.chrom != []:
    # Merge in one step

    # Get configured merge definition
    if args.vartype_svtype == 'snv_snv':
        config_def = 'nrid'
    else:
        config_def = 'nr:szro={}:offset={}'.format(int(args.ro_min * 100), args.offset_max)

    print('Merging with def: ' + config_def)
    sys.stdout.flush()

    # Merge
    df = pavlib.call.merge_haplotypes(
        args.bed_var_h1, args.bed_var_h2,
        args.callable_h1,args.callable_h2,
        config_def,
        threads=args.merge_threads,
        chrom=None
    )

    # Save BED
    df.to_csv(args.bed, sep='\t', index=False, compression='gzip')

else:
    # Concatenate merged chromosomes

    write_header = True

    with gzip.open(args.bed, 'wt') as out_file:
        for in_file_name in args.bed_chrom:

            df_iter = pd.read_csv(
                in_file_name,
                sep='\t', iterator=True, chunksize=20000
            )

            for df in df_iter:
                df.to_csv(
                    out_file,sep='\t', index=False, header=write_header
                )

                write_header = False