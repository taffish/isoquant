isoquant 4.0.0-r2

Purpose:
  Discover and quantify transcripts from Nanopore, PacBio CCS, or assembled
  long RNA reads; optional modes cover single-cell/spatial barcodes, fusion,
  exon/intron, PolyA/TSS, and static result plots.

Usage:
  taf-isoquant isoquant [IsoQuant options]
  taf-isoquant isoquant-detect-barcodes [options]
  taf-isoquant isoquant-visualize OUTPUT_DIR [options]

Start a bulk run:
  taf-isoquant isoquant --reference genome.fa --genedb genes.gtf --complete_genedb --fastq reads.fq.gz --data_type nanopore --threads 8 --output out

Other common tasks:
  taf-isoquant isoquant --reference genome.fa --fastq reads.fq.gz --data_type nanopore --analysis transcript_discovery --output denovo
  taf-isoquant isoquant --reference genome.fa --genedb genes.gtf --bam reads.sorted.bam --data_type pacbio_ccs --output bam-out
  taf-isoquant isoquant --reference genome.fa --genedb genes.gtf --fastq reads.fq.gz --data_type nanopore --mode tenX_v3 --barcode_whitelist barcodes.tsv.gz --output sc
  taf-isoquant isoquant-detect-barcodes --input reads.fq.gz --barcodes barcodes.tsv.gz --mode tenX_v3 --output sample
  taf-isoquant isoquant --test

Visualization:
  IsoQuant 4.0 plots need legacy read_assignments input. Request it with
  --large_output read_info read_assignments read2transcripts, or convert:
  taf-isoquant python -m isoquant_lib.scripts.convert_read_info --read_info out/SAMPLE/SAMPLE.read_info.tsv.gz --format read_assignments --output out/SAMPLE/SAMPLE.read_assignments.tsv
  printf '%s\n' ENSG00000123456 > genes.txt
  taf-isoquant isoquant-visualize out --gene_list genes.txt --viz_output plots

Required inputs:
  --reference           Reference genome FASTA, optionally gzipped.
  --fastq               Raw long-read FASTA/FASTQ file(s).
  --bam                 Coordinate-sorted and indexed long-read BAM file(s).
  --genedb              Optional GTF/GFF/gffutils DB; required for reference,
                        exon and fusion analyses.
  --data_type           nanopore, pacbio_ccs, or assembly.
  --barcode_whitelist   Required by applicable single-cell/spatial modes.

Key controls:
  --analysis            Select quantification, transcript_discovery,
                        exon_quantification, and/or fusion.
  --mode                Select bulk or a supported single-cell/spatial mode.
  --threads             Worker threads; upstream default is 16.
  --output              Output directory.
  --resume              Resume a compatible unfinished output.
  --force               Intentionally replace an existing output.
  --index               Reuse an explicit aligner index.
  --genedb_output       Put a converted annotation DB at an explicit location.

Key outputs:
  isoquant.log and alignment logs
  *.read_info.tsv.gz and transcript-model read tables
  reference/discovered count and TPM tables
  transcript-model and extended-annotation GTF
  exon, splice-junction, intron-retention, PolyA/TSS and optional fusion tables

Resources and persistence:
  Small PolyA/TSS models are bundled. Supply project-specific references,
  annotations, whitelists and reads explicitly; no external database/model
  download or TAFFISH database mount is required.
  Reuse generated indices or databases with explicit --index, --genedb and
  --genedb_output paths. A missing reference .fai is created under --output,
  never beside the input; an adjacent .fai is copied there before reuse. The internal
  path registry and library caches are temporary under /tmp so read-only SIFs
  remain usable.
  Docker writes bind-mounted outputs as the invoking UID/GID.

Backends and platforms:
  Native images are provided for linux/amd64 and linux/arm64.
  TAFFISH_CONTAINER_BACKEND=docker taf-isoquant isoquant --test
  TAFFISH_CONTAINER_BACKEND=podman taf-isoquant isoquant --test
  TAFFISH_CONTAINER_BACKEND=apptainer taf-isoquant isoquant --test
  Keep inputs, reusable indices and outputs on paths visible to the wrapper.
  isoquant-visualize is a batch plot command, not a GUI/browser service.

Important boundaries:
  The official --test replaces isoquant_test in the current directory.
  Use a new output directory unless --resume or --force is deliberate.
  Upstream 4.0.0 rejects --cage and does not load HDF5 barcode lists; use
  plain or gzip-compressed text whitelists.
  Production whole-genome runs may need substantial RAM, storage and time.

Help and command mode:
  taf-isoquant --help              This TAFFISH help.
  taf-isoquant -- --help           Default upstream IsoQuant help.
  taf-isoquant isoquant --full_help
  taf-isoquant isoquant --version
  Use the explicit packaged executable before upstream subcommands/options.

Detailed documentation: https://ablab.github.io/IsoQuant/ and https://github.com/ablab/IsoQuant
