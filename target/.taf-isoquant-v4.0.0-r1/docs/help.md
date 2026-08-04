isoquant 4.0.0-r1

Purpose:
  IsoQuant discovers and quantifies transcripts from Nanopore, PacBio CCS,
  or assembled long RNA reads. Version 4.0 also supports single-cell/spatial
  barcode processing, exon/intron counts, fusion calls, PolyA/TSS analysis,
  and result visualization.

Usage:
  taf-isoquant -- --help
  taf-isoquant -- --version
  taf-isoquant isoquant --full_help
  taf-isoquant isoquant --reference genome.fa --fastq reads.fq.gz --data_type nanopore --output out
  taf-isoquant isoquant --reference genome.fa --genedb genes.gtf --bam reads.sorted.bam --data_type pacbio_ccs --output out

Packaged commands:
  isoquant                     Main discovery and quantification pipeline.
  isoquant-detect-barcodes     Standalone barcode and UMI detection.
  isoquant-visualize           Plot genes from an IsoQuant result directory.
  minimap2, samtools           Default raw-read alignment and BAM handling.
  STAR, STARlong               Optional --aligner starlong path.
  python, python3              Locked Python 3.12 IsoQuant environment.

Common workflows:
  taf-isoquant isoquant --reference genome.fa --genedb genes.gtf --complete_genedb --fastq reads.fq.gz --data_type nanopore --threads 8 --output out
  taf-isoquant isoquant --reference genome.fa --fastq reads.fq.gz --data_type nanopore --analysis transcript_discovery --output denovo
  taf-isoquant isoquant --reference genome.fa --genedb genes.gtf --bam reads.bam --data_type nanopore --analysis quantification transcript_discovery exon_quantification fusion --output all
  taf-isoquant isoquant --reference genome.fa --genedb genes.gtf --fastq reads.fq.gz --data_type nanopore --mode tenX_v3 --barcode_whitelist barcodes.tsv.gz --output sc
  taf-isoquant isoquant --test

Helper workflows:
  taf-isoquant isoquant-detect-barcodes --input reads.fq.gz --barcodes barcodes.tsv.gz --mode tenX_v3 --output sample
  taf-isoquant python -m isoquant_lib.scripts.convert_read_info --read_info out/SAMPLE/SAMPLE.read_info.tsv.gz --format read_assignments --output out/SAMPLE/SAMPLE.read_assignments.tsv
  taf-isoquant isoquant-visualize out --gene_list genes.txt --viz_output plots

Inputs:
  --reference           Required reference genome FASTA, optionally gzipped.
  --genedb              Optional GTF/GFF/gffutils DB; required by reference,
                        exon and fusion analyses.
  --fastq               Raw long-read FASTA/FASTQ file(s), optionally gzipped.
  --unmapped_bam        Unmapped BAM file(s), mapped internally.
  --bam                 Coordinate-sorted and indexed long-read BAM file(s).
  --yaml                Multi-experiment input description.
  --illumina_bam        Optional short-read evidence for splice correction.
  --barcode_whitelist   Barcode list(s) for single-cell/spatial modes.
  --molecule            Custom molecule-description file for custom_sc mode.

Key controls:
  --data_type           nanopore, pacbio_ccs, or assembly.
  --analysis            quantification, transcript_discovery,
                        exon_quantification, and/or fusion.
  --mode                bulk, supported 10x/Visium/Curio/Stereo-seq mode,
                        or custom_sc.
  --threads             Worker threads; upstream default is 16.
  --large_output        Select or disable large per-read outputs.
  --resume              Resume a compatible unfinished output directory.
  --force               Intentionally replace a prior output directory.

Key outputs:
  isoquant.log, alignment logs, *.read_info.tsv.gz and model-read tables
  reference/discovered count and TPM tables, transcript-model/extended GTF
  exon, splice-junction and intron-retention counts
  PolyA/TSS prediction tables and optional fusion_*.tsv files

Platform and resources:
  Native platforms are linux/amd64 and linux/arm64. The image includes the
  complete CPU runtime, minimap2, samtools, STAR and STARlong. No external
  database is required, but users must provide references, annotations and
  barcode resources. Production runs can need substantial RAM and storage.

Boundaries:
  The offline smoke runs the official toy raw-read pipeline through minimap2
  and samtools, converts read_info to the legacy read_assignments format used
  by the 4.0 visualizer, and checks real PNG output. Request read_assignments
  during analysis or run the packaged converter before visualization.
  It does not scientifically validate every protocol, fusion call or plot.
  Upstream 4.0.0 rejects --cage and does not implement HDF5 barcode lists;
  provide barcode whitelists as plain or gzip-compressed text.
  The bundled PolyA/TSS models and toy data are small runtime assets. No
  production genome, annotation, whitelist or remote database is bundled.
  The official --test replaces isoquant_test in the current directory.

Detailed documentation:
  https://ablab.github.io/IsoQuant/
  https://github.com/ablab/IsoQuant

Wrapper options:
  taf-isoquant --help       Show this TAFFISH help.
  taf-isoquant -- --help    Pass --help to the default upstream isoquant command.
