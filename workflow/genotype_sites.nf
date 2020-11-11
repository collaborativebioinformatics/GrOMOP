#!/usr/bin/env nextflow

// genotype_sites.nf
// Given a list of variants,
// generate a samtools pileup at each
// variant site in the list,
// Transform that pileup into a Tidy format,
// and produce a small dataframe 


params.sites = "variants.tsv"
params.ref = "hg19.fa"
params.bam = "sample.bam"
params.bai = "sample.bam.bai"
params.sample = "SAMPLE"

bam_ch = Channel.fromPath(params.bam)
bai_ch = Channel.fromPath(params.bai)


// Produces a channel from the input TSV file
// (which should contain the columns chrom, start_pos, end_pos, ref, and alt).
// Each site in the file can then be processed in parallel.
Channel
    .fromPath(params.sites)
    .splitCsv(header:true,sep:"\t")
    .map{ row-> tuple(row.chrom, row.start_pos, row.end_pos) }
    .set { sites_ch }

process genotype_reads_at_site {

    publishDir "results"
    input:
        set chrom, start_pos, end_pos from sites_ch
        path ref from params.ref
        path bamSample from bam_ch
        path bamIndex from bai_ch
        val sample from params.sample

    
    output:
        path '*.pileup' into pileups
        path '*.counts.tsv' into readcounts


    script:
    """
    reg=\$(echo "$chrom $start_pos $end_pos" | awk '{print \$1":"\$2"-"\$3}') && \
    samtools mpileup --output-QNAME -f $ref -r \$reg -aO -o \$reg.pileup $bamSample && \ 
    transpose_mpileup_with_indels.py -s "$sample" -i \$reg.pileup > \$reg.tidy.pileup  && \
    count_variant_supports.R --input \$reg.tidy.pileup > $sample.\$reg.counts.tsv 
    """

}

