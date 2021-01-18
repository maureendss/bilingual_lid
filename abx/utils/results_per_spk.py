#!/usr/bin/env python 



if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("analyze_file", help="")
    parser.add_argument("--spk_column", default=1, help="column which contains all speakers (starts at 1)") 
    parser.parse_args()
    args, leftovers = parser.parse_known_args()


    categs = []

    with open(args.analyze_file, 'r') as infile:
        col=args.spk_column-1
        next(infile)
        for l in infile:
            spk=l.split()[col]
            if spk not in categs:
                categs.append(spk)
    for cat in categs:
        total=0.0
        num=0.0
        
        with open(args.analyze_file, 'r') as infile:
            next(infile)
            for l in infile:
                if cat in l:
                    num += float(l.split()[-2])*float(l.split()[-1])
                    total += float(l.split()[-1])
            if total!=0:
                # print(cat, num/total)
                print(cat, num/total*100)            
