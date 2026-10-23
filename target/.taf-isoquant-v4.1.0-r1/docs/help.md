isoquant 4.1.0-r1

Purpose:
  Discover and quantify long-read transcripts; produce count tables,
  transcript models, static plots and an offline HTML run summary.

Common tasks:
  taf-isoquant isoquant --reference genome.fa --genedb genes.gtf --complete_genedb --fastq reads.fq.gz --data_type nanopore --threads 8 --output out
  taf-isoquant isoquant --reference genome.fa --fastq reads.fq.gz --data_type nanopore --analysis transcript_discovery --output denovo
  taf-isoquant isoquant --reference genome.fa --genedb genes.gtf --bam reads.sorted.bam --data_type pacbio_ccs --output bam-out
  taf-isoquant isoquant --reference genome.fa --genedb genes.gtf --fastq reads.fq.gz --data_type nanopore --mode tenX_v3 --barcode_whitelist barcodes.tsv.gz --output sc
  taf-isoquant isoquant-detect-barcodes --input reads.fq.gz --barcodes barcodes.tsv.gz --mode tenX_v3 --output sample

Inputs and controls:
  --reference          Genome FASTA, plain or gzip.
  --genedb             GTF/GFF/gffutils DB; needed for reference analyses.
  --fastq / --bam       Long reads, or sorted and indexed alignments.
  --data_type          nanopore, pacbio_ccs or assembly.
  --analysis           quantification, transcript_discovery,
                       exon_quantification and/or fusion.
  --mode               Bulk or a supported single-cell/spatial chemistry.
  --barcode_whitelist  Text/gzip list, or auto to infer from input reads.
  --n_cells            Expected cell count or auto; no resource download.
  --split_molecules    auto, true or false; replaces split-specific modes.
  --threads            Worker threads (default 16).
  --output             Output directory; prefer a fresh directory.
  --resume             Resume compatible 4.1.0 output, not older-version runs.
  --force              Skip the existing-output warning; use with care.
  --index              Explicit reusable aligner index.
  --genedb_output      Directory for converted annotation databases.

View results:
  Open out/SAMPLE/SAMPLE.summary.html in a browser (offline, no server).
  Its plots and tables are static; summary_stats.json contains the data.
  For per-gene PNG plots, request --large_output read_info read_assignments
  read2transcripts during the run, or convert existing read information:
  taf-isoquant python -m isoquant_lib.scripts.convert_read_info --read_info out/SAMPLE/SAMPLE.read_info.tsv.gz --format read_assignments --output out/SAMPLE/SAMPLE.read_assignments.tsv
  printf '%s\n' ENSG00000123456 > genes.txt
  taf-isoquant isoquant-visualize out --gene_list genes.txt --viz_output plots

Key outputs:
  isoquant.log; read-info tables; reference/discovered counts and TPM;
  transcript-model/extended GTF; optional exon/fusion/PolyA/TSS tables;
  grouped matrices and RNA velocity loom files when applicable.

Resources:
  Small PolyA/TSS models are bundled; no separate model installation.
  Supply references, annotations and whitelists explicitly. Missing inputs
  fail; automatic barcode detection uses your reads, not the network.
  Generated FAI copies, indices and databases belong in writable output.
  To share a read-only reference directory, select the matching backend:
  TAFFISH_DOCKER_RUN_ARGS='-v /srv/reference:/reference:ro' TAFFISH_CONTAINER_BACKEND=docker taf-isoquant isoquant --reference /reference/genome.fa --fastq reads.fq.gz --data_type nanopore --output out
  TAFFISH_PODMAN_RUN_ARGS='-v /srv/reference:/reference:ro' TAFFISH_CONTAINER_BACKEND=podman taf-isoquant isoquant --reference /reference/genome.fa --fastq reads.fq.gz --data_type nanopore --output out
  TAFFISH_APPTAINER_RUN_ARGS='--bind /srv/reference:/reference:ro' TAFFISH_CONTAINER_BACKEND=apptainer taf-isoquant isoquant --reference /reference/genome.fa --fastq reads.fq.gz --data_type nanopore --output out
  Replace /srv/reference with a readable host directory; VM backends need
  host file-sharing access. Keep outputs on a writable wrapper-visible path.

Backends:
  Native linux/amd64 and linux/arm64 images; Docker, Podman or Apptainer.
  TAFFISH_CONTAINER_BACKEND=docker taf-isoquant isoquant --test
  TAFFISH_CONTAINER_BACKEND=podman taf-isoquant isoquant --test
  TAFFISH_CONTAINER_BACKEND=apptainer taf-isoquant isoquant --test
  WARNING: --test replaces isoquant_test in the current directory.
  HTML/PNG files are viewed on the host; no GUI port or GPU is required.

Immediate notes:
  Existing output can be overwritten after a warning even without --force!
  Use plain/gzip text whitelists: upstream HDF5 whitelist loading is absent.
  --cage is not supported upstream. Do not resume pre-4.1.0 partial runs.
  Large projects need appropriate RAM, storage and thread allocation.
  Review report command-line paths before sharing reports.

More help:
  taf-isoquant isoquant --full_help
  https://ablab.github.io/IsoQuant/
  https://github.com/taffish/isoquant

Wrapper options:
  taf-isoquant --help       This installed-wrapper help.
  taf-isoquant --version    TAFFISH wrapper version.
  taf-isoquant --compile    Generated shell.
  taf-isoquant -- --help    Default upstream help.
  taf-isoquant isoquant --version
