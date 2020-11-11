#!/usr/bin/env nextflow

// genotype_sites.nf
// Given a list of variants,
// generate a samtools pileup at each
// variant site in the list,
// Transform that pileup into a Tidy format,
// and produce a small dataframe 

params.sites = "variants.tsv"
params.reference = "hg19.fa"

// Produces a channel from the input TSV file
// (which should contain the columns chrom, start_pos, end_pos, ref, and alt).
// Each site in the file can then be processed in parallel.
Channel
    .fromPath(params.sites)
    .splitCsv(header:true,sep:"\t")
    .map{ row-> tuple(row.chrom, row.start_pos, row.end_pos) }
    .set { sites_ch }

process genotype_reads_at_site {
    input:
    set chrom, start_pos, end_pos from sites_ch
    file ref from params.reference

    script:
    """
    reg=\$(echo "$chrom $start_pos $end_pos" | awk '{print \$1":"\$2"-"\$3}') && \
    #samtools mpileup --output-QNAME -ao -f $ref -r \$reg $bamfile | \
    samtools mpileup --output-QNAME -ao -r \$reg $bamfile | \
    python transpose_mpileup_with_indels.py $sample > \$reg.pileup && \
    Rscript src/R/count_variant_sites.R --input \$reg.pileup > \$reg.counts.tsv 
    """
}

