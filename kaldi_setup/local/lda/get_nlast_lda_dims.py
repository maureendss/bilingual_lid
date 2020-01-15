#!/usr/bin/env python 

import numpy as np
import kaldiio
import os, shutil
import pandas as pd



if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("lda_mat", help="original lda matrix (kaldi .mat)")
    parser.add_argument("out_lda_mat", help="new lda matrix to write on")
    parser.add_argument("--tgt_dim", type=int, default=5, help="number of dims kept (from end of the matrix)")
    parser.parse_args()
    args, leftovers = parser.parse_known_args()

    # Check if n is at least one less dim than the original matrix

    #load matrix
    orig_mat = kaldiio.load_mat(args.lda_mat)


    if orig_mat.shape[0] <= args.tgt_dim:
        raise ValueError("Original matrix has less or same amount of dimensions ({}) than the target dim chosen for the new matrix ({})".format(orig_mat.shape[0], args.tgt_dim))

    new_mat = orig_mat[-args.tgt_dim-1:-1]

    kaldiio.save_mat(args.out_lda_mat, new_mat)
