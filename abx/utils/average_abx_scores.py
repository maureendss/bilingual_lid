#!/usr/bin/env python 



if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("analyze_file", help="")
    parser.parse_args()
    args, leftovers = parser.parse_known_args()

    
with open(args.analyze_file, 'r') as infile:
    next(infile)
    total=0.0
    num=0.0
    for l in infile:
        num += float(l.split()[-2])*float(l.split()[-1])
        total += float(l.split()[-1])


print(num / total)
