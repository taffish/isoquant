# isoquant

`isoquant` packages [IsoQuant](https://github.com/ablab/IsoQuant) for TAFFISH.

Package identity:

- name: `isoquant`
- command: `taf-isoquant`
- kind: `tool`
- TAFFISH version: `4.0.0-r2`
- TAFFISH app license: Apache-2.0
- upstream release: `ablab/IsoQuant` `v4.0.0`
- runtime version: `IsoQuant 4.0.0`
- container image: `ghcr.io/taffish/isoquant:4.0.0-r2`
- native platforms: `linux/amd64`, `linux/arm64`
- default upstream command: `isoquant`

## Installation

```sh
taf update
taf install isoquant
```

For local validation before publication, use `taf install --from .` in this
app directory.

## What This App Packages

IsoQuant performs genome-based discovery, classification and quantification of
transcripts from long RNA reads. It accepts Oxford Nanopore, PacBio CCS and
assembled transcript data as raw FASTA/FASTQ, unmapped BAM, or pre-aligned
sorted and indexed BAM. A reference genome is required; a reference gene
annotation is optional for transcript discovery and required by analyses that
compare against or quantify reference features.

This image installs the official IsoQuant `4.0.0` release asset with its
published SHA256. The Python 3.12 environment is version-locked, and the image
includes minimap2, samtools, STAR and STARlong so upstream raw-read alignment
paths do not borrow tools from the host.

## Scope

The app supports the IsoQuant 4.0 command surface for:

- bulk reference-guided and annotation-free transcript discovery
- reference gene and transcript quantification
- exon, splice-junction and intron-retention counting
- fusion-gene detection when a reference annotation is provided
- PolyA-site and transcription-start-site discovery
- raw FASTA/FASTQ and unmapped BAM alignment with minimap2 plus samtools
- pre-aligned, coordinate-sorted and indexed BAM input
- optional STARlong alignment selected with `--aligner starlong`
- multiple files and YAML-described experiments
- short-read BAM evidence for splice-site correction
- single-cell and spatial modes for 10x v2/v3, Visium, Visium HD, Curio,
  Stereo-seq and custom molecule-description files
- barcode/UMI extraction and deduplication
- grouped, matrix and MTX count outputs
- IsoQuant result visualization

The image does not bundle reference genomes, gene annotations, barcode
whitelists, short-read alignments or production sequencing data. Those are
project-specific inputs and should remain explicit files.

## Container Contents

- `isoquant`: main upstream pipeline and default command
- `isoquant-detect-barcodes`: standalone barcode and UMI detection
- `isoquant-visualize`: plots an existing IsoQuant result directory
- `minimap2` and `samtools`: default raw-read alignment path
- `STAR` and `STARlong`: optional STARlong alignment path
- `python` and `python3`: locked IsoQuant Python environment
- `python -m isoquant_lib.gtf2db`: GTF/GFF and gffutils DB conversion
- `python -m isoquant_lib.quantification.convert_grouped_counts`: count format conversion
- `python -m isoquant_lib.scripts.convert_read_info`: unified read-info conversion
- `python -m isoquant_lib.scripts.prepare_visium_spot_ids`: Visium spot mapping helper
- `python -m isoquant_lib.scripts.inject_bam_tags`: barcode/UMI BAM tag helper

Small upstream PolyA/TSS JSON models and the official toy dataset used by
`isoquant --test` are retained. They are runtime assets, not external
production databases.

## Runtime Write Map

The image installation under `/opt/isoquant` is immutable at runtime. IsoQuant
4.0.0 creates four small path registries at startup; this release makes it honor
`XDG_CONFIG_HOME` and points that path, `HOME`, Matplotlib, Numba and the other
XDG scratch/cache paths below `/tmp`. Initialization therefore remains
temporary even when TAFFISH passes the host HOME into a read-only SIF or
container.

Scientific outputs, converted annotations, aligner indices and alignments are
written to the current project directory or the paths selected with
`--output`, `--genedb_output` and `--index`. When a reference has no adjacent
`.fai`, the TAFFISH package stores the newly generated pyfaidx index below
`--output` instead of modifying the input directory; an existing adjacent
`.fai` is copied there before reuse or any required rebuild. The temporary HOME
registry is not a persistent database. Across separate wrapper invocations,
reuse generated resources by passing the same explicit project-visible
`--index`, preconverted `--genedb`,
sorted/indexed `--bam`, or other input path. Docker runs the container as the
invoking host UID/GID so bind-mounted outputs are not left root-owned; rootless
Podman and ordinary-user Apptainer retain their normal host-user ownership.

## Usage

Show wrapper and upstream help:

```sh
taf-isoquant --help
taf-isoquant -- --help
taf-isoquant isoquant --full_help
taf-isoquant isoquant --version
```

Run bulk analysis from raw Nanopore reads:

```sh
taf-isoquant isoquant \
  --reference genome.fa \
  --genedb genes.gtf \
  --complete_genedb \
  --fastq reads.fastq.gz \
  --data_type nanopore \
  --threads 8 \
  --output isoquant-out \
  --prefix sample
```

Run annotation-free transcript discovery:

```sh
taf-isoquant isoquant \
  --reference genome.fa \
  --fastq reads.fastq.gz \
  --data_type nanopore \
  --analysis transcript_discovery \
  --output isoquant-denovo
```

Run from an existing sorted and indexed BAM:

```sh
taf-isoquant isoquant \
  --reference genome.fa \
  --genedb genes.gtf \
  --complete_genedb \
  --bam reads.sorted.bam \
  --data_type pacbio_ccs \
  --output isoquant-bam
```

Request additional analysis classes:

```sh
taf-isoquant isoquant \
  --reference genome.fa \
  --genedb genes.gtf \
  --complete_genedb \
  --bam reads.sorted.bam \
  --data_type nanopore \
  --analysis quantification transcript_discovery exon_quantification fusion \
  --output isoquant-all
```

Run 10x single-cell analysis:

```sh
taf-isoquant isoquant \
  --reference genome.fa \
  --genedb genes.gtf \
  --complete_genedb \
  --fastq reads.fastq.gz \
  --data_type nanopore \
  --mode tenX_v3 \
  --barcode_whitelist barcodes.tsv.gz \
  --output isoquant-sc
```

Use the standalone barcode helper:

```sh
taf-isoquant isoquant-detect-barcodes \
  --input reads.fastq.gz \
  --barcodes barcodes.tsv.gz \
  --mode tenX_v3 \
  --threads 8 \
  --output sample
```

The 4.0 visualizer consumes legacy `*.read_assignments.tsv`. Request that file
during the main run with `--large_output read_info read_assignments
read2transcripts`, or convert a default `read_info` result before plotting:

```sh
taf-isoquant python -m isoquant_lib.scripts.convert_read_info \
  --read_info isoquant-out/SAMPLE/SAMPLE.read_info.tsv.gz \
  --format read_assignments \
  --output isoquant-out/SAMPLE/SAMPLE.read_assignments.tsv
printf '%s\n' ENSG00000123456 > genes.txt
taf-isoquant isoquant-visualize \
  isoquant-out \
  --gene_list genes.txt \
  --viz_output isoquant-plots
```

Run the official bundled toy analysis:

```sh
taf-isoquant isoquant --test
```

`--test` writes `isoquant_test` in the current directory and replaces an
existing directory of that name.

## Command Mode

This is a normal TAFFISH tool app with automatic command mode. Use
`taf-isoquant isoquant ...` for the main upstream command and
`taf-isoquant isoquant-detect-barcodes ...` or
`taf-isoquant isoquant-visualize ...` for packaged helpers.

Option-leading arguments can also be sent to the default command:

```sh
taf-isoquant -- --version
taf-isoquant -- --help
```

Do not write `taf-isoquant detect-barcodes ...`; the real packaged executable
is named `isoquant-detect-barcodes`.

## Inputs

| Input | Meaning | Notes |
| --- | --- | --- |
| `--reference` | reference genome FASTA | required, plain or gzip-compressed |
| `--genedb` | GTF, GFF or gffutils DB | optional for discovery; needed for reference analyses |
| `--fastq` | long-read FASTA/FASTQ files | plain or gzip-compressed; mapped internally |
| `--unmapped_bam` | unmapped long-read BAM | converted and mapped internally |
| `--bam` | aligned long-read BAM | must be coordinate-sorted and indexed |
| `--illumina_bam` | short-read alignment evidence | optional splice-site correction only |
| `--yaml` | multi-experiment description | paths may be relative to the YAML file |
| `--barcode_whitelist` | cell or spot barcode list | mode-specific; one or two lists may be required |
| `--molecule` | custom molecule description | used by `custom_sc` mode |

Do not trim PolyA tails unless the library preparation requires it; upstream
uses terminal sequence evidence. When tails were trimmed, choose the documented
`--polya_trimmed` mode deliberately.

## Output Notes

IsoQuant creates the requested `--output` directory. Depending on `--analysis`
and `--mode`, important outputs include:

- `isoquant.log` and alignment logs
- `*.read_info.tsv.gz` and `*.transcript_model_reads.tsv.gz`
- reference `*.gene_counts.tsv`, `*.transcript_counts.tsv` and TPM tables
- discovered `*.transcript_models.gtf` and `*.extended_annotation.gtf`
- discovered gene/transcript count and TPM tables
- exon, splice-junction and intron-retention count tables
- PolyA and TSS prediction tables
- `fusion_<bam-basename>.tsv` when fusion analysis is requested
- per-group dense, sparse matrix and MTX outputs when grouping is enabled

Use `--large_output` to control large per-read files. Use `--resume` only with
an unfinished compatible run; use `--force` when intentionally replacing an
existing output. A fresh output directory remains the safest default.

## Resources, Databases, and Platform

Native image platforms are `linux/amd64` and `linux/arm64`. Both use the same
Python package lock and Debian runtime tools.

| Backend | Supported contract |
| --- | --- |
| Docker | Native amd64/arm64 image; wrapper applies the invoking UID/GID. |
| Podman | Native amd64/arm64 image; ordinary rootless execution. |
| Apptainer | Read-only SIF; configuration and runtime caches use `/tmp`. |

No database/model download helper or fixed container database mount is
required. The small PolyA/TSS JSON models are fixed assets of the official
v4.0.0 distribution and stay in the image. Reference genomes, annotations,
barcode whitelists and sequencing data are project-specific scientific inputs,
not canonical assets published by IsoQuant, so the app does not auto-download or
auto-select them. A minimap2 index or converted gffutils database is also tied
to the user's chosen reference; create or obtain it deliberately and reuse it
through the upstream `--index`, `--genedb` and `--genedb_output` interfaces.
There is consequently no personal/system-wide TAFFISH database helper or
automatic database/model mount for this app.

IsoQuant defaults to 16 threads. Whole-genome long-read projects can require
substantial RAM, temporary storage and output space, especially with
per-read/grouped output or many barcodes. Set `--threads` for the allocated
resources and keep input, output and any reusable minimap2 index on
container-visible paths.

The image intentionally uses the official `xgboost-cpu` 2.1.4 runtime. IsoQuant
uses the bundled XGBoost models for CPU inference and does not expose a
GPU-only analysis mode, so this avoids unrelated CUDA/NCCL payload without
removing an IsoQuant feature. Scikit-learn is fixed at 1.7.2 to retain the
estimator interface required by XGBoost 2.1.4; unbounded resolution to
scikit-learn 1.9 breaks the bundled model-loading path. Debian `libtbb12`
closes the x86_64 wheel's architecture-specific dynamic-library dependency;
the aarch64 wheel does not link TBB.

## Boundaries

- The default raw-read path is minimap2 plus samtools and is covered by the
  official toy pipeline smoke.
- STARlong is packaged and its runtime identity is checked, but the smoke does
  not build a production STAR genome index or compare STARlong alignments.
- Single-cell, spatial and fusion command surfaces and dependencies are
  included; the quick smoke does not reproduce every protocol or validate
  biological accuracy on production data.
- IsoQuant 4.0.0 itself rejects the hidden `--cage` option as unsupported.
  Barcode whitelists must be text or gzip-compressed text: its HDF5 loader is
  also explicitly unimplemented upstream. Installing `pybedtools` or `h5py`
  would not enable either path, so they are intentionally not bundled.
- The smoke converts the official toy `read_info` output to the legacy format
  consumed by `isoquant-visualize` and checks real PNG outputs. It does not
  treat one synthetic plot or barcode helper help as protocol validation.
- No network resource is needed by the normal smoke. Real references,
  annotations and whitelists remain user-managed inputs.
- `isoquant-visualize` is the upstream batch CLI that writes static plots; it
  is not a browser service, desktop GUI, noVNC session or long-running helper.
  IsoQuant v4.0.0 declares only a `test` package extra, and the upstream
  organization exposes no separate official IsoQuant GUI companion repository.

## Troubleshooting

- If a BAM run reports that the file is not indexed, coordinate-sort it and
  create `.bai` or `.csi` before running IsoQuant.
- If GTF conversion is slow, use `--complete_genedb` for official annotations
  that already contain gene and transcript meta-features.
- If an output directory already exists, use a new directory, `--resume`, or
  the explicit destructive `--force` option as appropriate.
- If barcode calling fails, confirm the selected `--mode`, whitelist count,
  molecule structure and barcode/UMI orientation match the library protocol.

## Testing

The smoke suite checks:

- exact IsoQuant `4.0.0` runtime and locked Python imports
- `isoquant`, barcode helper and visualizer help surfaces
- minimap2, samtools, STAR and STARlong runtime identities
- packaged annotation/count/read-info/Visium/BAM helper modules
- upstream `isoquant --test` on bundled reads, reference and annotation
- minimap2-to-samtools alignment, BAM indexing, transcript-model GTF and count output
- read-info conversion and real `isoquant-visualize` PNG output
- dynamic-library resolution for installed Python extension modules

The full pipeline test is run offline and independently in a fresh container.
It is integration coverage, not a benchmark or a scientific validation of all
IsoQuant 4.0 modes.

## License and Citation

TAFFISH app packaging is Apache-2.0.

IsoQuant is distributed under GPL-2.0-only. The image retains the upstream
license text and GPL v2 copy under `/opt/isoquant/share/licenses/isoquant`.

For IsoQuant transcript discovery and quantification, cite:

Prjibelski AD, Mikheenko A, Joglekar A, et al. Accurate isoform discovery with
IsoQuant using long reads. Nature Biotechnology. 2023;41:915-918.
doi:10.1038/s41587-022-01565-y. PMID:36593406.

Protocol-specific single-cell/spatial citation guidance is maintained in the
[upstream citation documentation](https://ablab.github.io/IsoQuant/citation/).
