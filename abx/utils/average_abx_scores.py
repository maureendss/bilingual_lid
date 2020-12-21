#!/usr/bin/env python 



if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("analyze_file", help="")
    parser.add_argument("--categ_list", help="list of categories separated by spaces", default="")
    parser.parse_args()
    args, leftovers = parser.parse_known_args()

if args.categ_list:
    categs = args.categ_list.split(" ")
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

                
else:     
    with open(args.analyze_file, 'r') as infile:
        next(infile)
        total=0.0
        num=0.0
        for l in infile:
            num += float(l.split()[-2])*float(l.split()[-1])
            total += float(l.split()[-1])


    print(num / total)
