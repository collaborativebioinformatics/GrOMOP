#!/usr/bin/env python
from __future__ import print_function
import sys
import argparse

def write_err(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", help="An input pileup file.", type=str, dest="pileup")
    parser.add_argument("-s", "--sample", help="A sample name to annotate output with.", type=str, default="sample")
    return parser.parse_args()

if __name__ == "__main__":
    
    SAMPLE="SAMPLE"
    if len(sys.argv) == 2:
        SAMPLE=sys.argv[1]

    args = parse_args()

    header = "Chromosome\tPosition\tREF\tVariant_Type\tALT\tQNAME\tSAMPLE"
    print(header)
    with open(args.pileup, "r") as pileup_file:
        for line in pileup_file:
            line = line.strip()
            tokens = line.split("\t")

            chrom = tokens[0]
            pos = tokens[1]
            ref_allele = tokens[2]
            read_count = tokens[3]
            alt_alleles = tokens[4]
            quals = tokens[5]
            read_names = tokens[6]

            prefix = "\t".join([chrom, pos, ref_allele])

            read_name_splits = read_names.split(",")

            allele_index = 0
            name_index = 0
            while name_index < len(read_name_splits):
                #write_err(read_count, len(alt_alleles), allele_index, name_index)
                if alt_alleles[allele_index] == "+" or alt_alleles[allele_index] == "-":
                    vtype= "DEL" if alt_alleles[allele_index] == "-" else "INS"
                    insert = ""
                    insertion_len = 0
                    len_str = ""
                    j = 0
                    allele_index+=1
                    while alt_alleles[allele_index + j].isdigit():
                        len_str += alt_alleles[allele_index + j]
                        j+=1
                    insertion_len = int(len_str)
                    insert = alt_alleles[allele_index+j:allele_index+j+insertion_len]
                    allele_index += len(len_str) + len(insert) - 1
                    write_err("INSERTION DETECTED: len=" + str(insertion_len), "seq=" + insert, read_name_splits[name_index])
                    print("\t".join([prefix, vtype, insert, read_name_splits[allele_index], args.sample]))
                else:
                    print("\t".join([prefix, "SNV", alt_alleles[allele_index], read_name_splits[name_index], args.sample]))
                allele_index += 1
                name_index += 1

