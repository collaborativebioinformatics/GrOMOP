#!/usr/bin/env nextflow

// genotype_sites.nf
// Given a list of variants,
// generate a samtools pileup at each
// variant site in the list,
// Transform that pileup into a Tidy format,
// and produce a small dataframe containing the
// counts of reads in params.bam supporting each allele at the site.

// Takes as required arguments:
// A file of variants in TSV format, with the first five columns being chrom, start_pos, end_pos, ref, alt
params.sites = "variants.tsv"
// A FASTA reference file (should have a corresponding FAI index).
params.ref = "hg19.fa"
// A BAM file
params.bam = "sample.bam"
// A corresponding BAM index.
params.bai = "sample.bam.bai"
// And, optionally, a sample name.
params.sample = "SAMPLE"

// Produces a channel from the input TSV file
// (which should contain the columns chrom, start_pos, end_pos, ref, and alt).
// Each site in the file can then be processed in parallel.
Channel
    .fromPath(params.sites)
    .splitCsv(header:true,sep:"\t")
    .map{ row-> tuple(row.chrom, row.start_pos, row.end_pos) }
    .set { sites_ch }

process genotype_reads_at_site {
    // Store results in a new directory called 'results'
    publishDir "results"
    input:
        set chrom, start_pos, end_pos from sites_ch
        path ref from params.ref
        path bamSample from params.bam
        path bamIndex from params.bai
        val sample from params.sample

    
    // Output the pileups into results, and send the local file.counts.tsv from
    // each process to the final aggregator where it will get recombined into a single file.
    output:
        path '*.pileup' into pileups
        path 'file.counts.tsv' into counts_ch


    /// Main script body.
    /// First, generate a samtools region string from the chrom, start_pos and end_pos
    /// Then generate a samtools mpileup (which must contain readnames) at a single site for the BAM proviced.
    /// Next, transpose the pileup file into a tidy-data formatted version.
    /// Finally, count the number of reads supporting each allele and write a small dataframe to a file.
    script:
    """
    reg=\$(echo "$chrom $start_pos $end_pos" | awk '{print \$1":"\$2"-"\$3}') && \
    samtools mpileup --output-QNAME -f $ref -r \$reg -o \$reg.pileup $bamSample && \ 
    transpose_mpileup_with_indels.py -s "$sample" -i \$reg.pileup > \$reg.tidy.pileup  && \
    count_variant_supports.R --input \$reg.tidy.pileup > file.counts.tsv
    """
}

/// Gather the "file.counts.tsv" files from each process (i.e., line in the input TSV)
/// and merge them back together into a single file with one header.
counts_ch
    .collectFile(name:'site_counts.tsv', sort: false, newLine: false, keepHeader:true, skip:1)
    .view{it.text}