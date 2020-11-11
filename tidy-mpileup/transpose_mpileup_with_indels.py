from __future__ import print_function
import sys

def write_err(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

if __name__ == "__main__":
    
    SAMPLE="SAMPLE"
    if len(sys.argv) == 2:
        SAMPLE=sys.argv[1]

    header = "Chromosome\tPosition\tREF\tVariant_Type\tALT\tQNAME\tSAMPLE"
    print(header)
    for line in sys.stdin:
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
                print("\t".join([prefix, vtype, insert, read_name_splits[allele_index], SAMPLE]))
            else:
                print("\t".join([prefix, "SNV", alt_alleles[allele_index], read_name_splits[name_index], SAMPLE]))
            allele_index += 1
            name_index += 1

