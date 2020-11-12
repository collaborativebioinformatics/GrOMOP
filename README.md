GrOMOP
--------------------
November 2020

## Background:
The number of individuals sequenced worldwide has grown considerably
in the last five years, particularly as precision medicine initiatives
have sought to improve healthcare using genetic information. Sequencing of
patients - particularly those diagnosed with cancer - is becoming routine in
clinical settings. There has been a concurrent acceleration in the development
of electronic health records, partially driven by adoption of new standards for sharing
such data(https://www.hl7.org/fhir/index.html, https://www.ohdsi.org/data-standardization/the-common-data-model/).


The Observational Medical Outcomes Partnership (OMOP) Common Data Model provides a framework
for analyzing data across electronic medical records and claims data using standard entity relationships and vocabularies.
This model is extensible, allowing new datatypes to be integrated as they are developed.

Here, we describe gromop, which leverages OMOP to drive highly sensitive genetic analysis
and provide sample-level provenance using a simple high-level user interface. This repo implements an analysis-as-data-model method which
progressively updates a set of variants in samples/cohorts, with a focus on variants
associated with cancer. The benefits of our model lie in its ease-of-use and in the 
enhanced sensitivity for detecting specific mutations of interest.

## Description
gromop (also styled GrOMOP) provides an OMOP-driven workflow for
variant-of-interest assessment in the context of cancer.

### The Enhanced Variant Set (EVS)
An _enhanced variant set_ is a set of variants in VCF, MAF, or TSV format. For
TSV files, the following columns must exist:
- chrom
- start_pos
- end_pos
- ref
- alt

Variants are read in by a reader function and stored in a minimal dataframe.
When a new set of sequencing reads is loaded, those reads are genotyped for
the presence of variants within the EVS. For each variant that's present,
the EVS is updated with a summary count of the number of reads and the number
of samples supporting the variant.

Multiple EVS may be applied to a given sample or sample set. The set of variants
present (i.e., which have a sample / read count above a set threshold) can
then be extracted, producing a _cohort_ EVS. The cohort set represents the variants
of interest present within the samples based upon the input enhanced variant sets.

What makes enhanced variant sets "enhanced?" The EVS provides a simple framework for
associating a set of variants with a specific condition (e.g., driver-associated variants
or those associated with metastasis). In addition, these variants are force-genotyped
in the cohort, providing enhanced variant calls at the locations in the EVS.

### Enhancing variant call sensitivity
We have considered multiple methods for enhancing variant call sensitivity and will breifly
describe three below.

1. Pileup-based variant detection: a pileup of reads over a site of interest in the EVS is generated from an input BAM and, if a sufficient number of reads support the variant of interest, the variant is labeled as present.
2. Enhanced sequence-based local realignment: an alternate sequence is generated from the alt allele and flanking reference portions. Reads are extracted and realigned to this sequence and the original reference sequence and then the pileup-based variant detector is used to determine if the variant is present.
3. Graph genome-based local realignment: a local variant graph is made of the alleles in the variant. Reads are realigned to this graph and then a variant presence call is made from the alignments.

### Risk notification 

### Progressive variant set construction
One of the key features of gromop is that inference improves with each EVS and sample added. New samples contribute read / sample count summary statistics as well as new variants. These are then incorporated into the cohort EVS. The addition of new variation as samples are added means that the EVS progressively improves in how well it models the cohort.

### Encoding metastatic relationships between EVS sets
OMOP can be used to establish relationships between sets of variants. In gromop, we aim to provide one clear example of an encoding between the variants sets of a normal, tumor, and metastatic specimen all from one patient.

### EVS serialization and sharing
Because an EVS or cohort EVS contains no direct sample-level information (i.e. no genotypes, phasing information, or sample metadata), they are largely anonymized and can be shared once read count info is removed. Since we encode an EVS in a dataframe, the EVS can be serialized to a file. This file can then be incorporated into an OMOP record for the study or patient. A patient's risk profile can quickly be reconstituted by someone with access to the sequencing reads, without exposing information about other individuals in the cohort.


