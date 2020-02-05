#!/usr/bin/env python 

import numpy as np
import kaldiio
import os, shutil
import pandas as pd
import scipy.linalg


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("lda_mat", help="original lda matrix (kaldi .mat)")
    parser.add_argument("out_lda_mat", help="new lda matrix to write on")
    parser.parse_args()
    args, leftovers = parser.parse_known_args()

    # Check if n is at least one less dim than the original matrix

    #load matrix
    orig_mat = kaldiio.load_mat(args.lda_mat)


    # new_mat = scipy.linalg.orth(orig_mat)
    # new_mat, r = np.linalg.qr(np.transpose(orig_mat), mode="complete")
    # q,r=np.linalg.qr(np.transpose(orig_mat))
    # new_mat=q.T


    #B <- t(qr.Q(qr(A),complete=TRUE)[,5:10])
    # is same as
    #q,r = np.linalg.qr(a)
    #mat=q.T

    #MAYBE need to transpose other way round (before calculating?) OR NOT TRANSPOSE the second time?

    a=orig_mat.T
    q,r=np.linalg.qr(a, mode='complete')
    z = q.T[-(a.shape[0]-a.shape[1]):] #get the last rows which are not in the original subspace.

    new_mat=z
    #np.dot(new_mat,a) Not needed but to show that orthogonal as == 0. 
    # new_mat=z.T #Transpose again as had to transpose the first (makes sense?)

    
    kaldiio.save_mat(args.out_lda_mat, new_mat)
