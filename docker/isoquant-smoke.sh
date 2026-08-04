#!/bin/sh
set -eu

mode="${1:-all}"

say() {
  printf 'isoquant-smoke: %s\n' "$*" >&2
}

run_identity() {
  say "identity"
  isoquant --version 2>&1 | grep -Fx 'IsoQuant 4.0.0' >/dev/null
  isoquant --help 2>&1 | grep -F 'Reference data:' >/dev/null
  isoquant --full_help 2>&1 | grep -F -- '--analysis' >/dev/null
  isoquant --full_help 2>&1 | grep -F -- '--aligner' >/dev/null
  isoquant-detect-barcodes --help 2>&1 | grep -F -- '--barcodes' >/dev/null
  isoquant-visualize --help 2>&1 | grep -F 'Visualize your IsoQuant output' >/dev/null
  minimap2 --version 2>&1 | grep -F '2.24' >/dev/null
  samtools --version 2>&1 | sed -n '1p' | grep -Fx 'samtools 1.16.1' >/dev/null
  STAR --version 2>&1 | grep -F '2.7.10b' >/dev/null
  STARlong --version 2>&1 | grep -F '2.7.10b' >/dev/null
  command -v zcat >/dev/null
  python - <<'PY'
import importlib.metadata as md

import Bio
import editdistance
import gffutils
import intervaltree
import mappy
import matplotlib
import numba
import numpy
import pandas
import pyfaidx
import pysam
import scipy
import seaborn
import sklearn
import ssw
import xgboost
import yaml

assert md.version("isoquant") == "4.0.0"
assert md.version("scikit-learn") == "1.7.2"
assert md.version("xgboost-cpu") == "2.1.4"
assert xgboost.__version__ == "2.1.4"
PY
}

run_modules() {
  say "helper-modules"
  python -m isoquant_lib.gtf2db --help 2>&1 | grep -F -- '--complete_genedb' >/dev/null
  python -m isoquant_lib.quantification.convert_grouped_counts --help 2>&1 | grep -F -- '--output_format' >/dev/null
  python -m isoquant_lib.scripts.convert_read_info --help 2>&1 | grep -F -- '--read_info' >/dev/null
  python -m isoquant_lib.scripts.prepare_visium_spot_ids --help 2>&1 | grep -F -- '--barcode_delimiter' >/dev/null
  python -m isoquant_lib.scripts.inject_bam_tags --help 2>&1 | grep -F -- '--barcoded_reads' >/dev/null
}

run_pipeline() {
  say "upstream-toy-pipeline"
  tmp="/tmp/taf-isoquant-pipeline-$$"
  rm -rf "$tmp"
  mkdir -p "$tmp"
  cd "$tmp"
  isoquant --test > run.log 2>&1
  if grep -E 'CRITICAL|Traceback|=== TEST FAILED ===' run.log >/dev/null; then
    cat run.log >&2
    exit 1
  fi
  grep -F '=== TEST PASSED CORRECTLY ===' run.log >/dev/null
  test -s isoquant_test/isoquant.log
  grep -F 'Total assignments used for analysis: 407, polyA tail detected in 223' isoquant_test/isoquant.log >/dev/null
  grep -F '  unique: 137' isoquant_test/isoquant.log >/dev/null
  grep -F '  known: 28' isoquant_test/isoquant.log >/dev/null
  grep -F 'Processed 1 experiment' isoquant_test/isoquant.log >/dev/null
  find isoquant_test -type f -name '*.bam' | grep -F '.bam' >/dev/null
  find isoquant_test -type f -name '*.bam.bai' | grep -F '.bam.bai' >/dev/null
  find isoquant_test -type f -name '*.transcript_models.gtf' | grep -F '.transcript_models.gtf' >/dev/null
  find isoquant_test -type f -name '*.gene_counts.tsv' | grep -F '.gene_counts.tsv' >/dev/null
  bam="$(find isoquant_test -type f -name '*.bam' | sed -n '1p')"
  samtools quickcheck "$bam"
  python -m isoquant_lib.scripts.convert_read_info \
    --read_info isoquant_test/TEST_DATA/TEST_DATA.read_info.tsv.gz \
    --format read_assignments \
    --output isoquant_test/TEST_DATA/TEST_DATA.read_assignments.tsv
  isoquant-visualize isoquant_test \
    --gene_list /dev/null \
    --find_genes 1 \
    --viz_output visualization > visualization.log 2>&1
  if grep -E 'CRITICAL|Traceback' visualization.log >/dev/null; then
    cat visualization.log >&2
    exit 1
  fi
  test -s visualization/combined_visualization.png
  test -s visualization/read_assignment_consistency_pie_chart.png
  test -s visualization/top_1_genes.txt
  rm -rf "$tmp"
}

case "$mode" in
  identity) run_identity ;;
  modules) run_modules ;;
  pipeline) run_pipeline ;;
  buildtime)
    run_identity
    run_modules
    ;;
  all)
    run_identity
    run_modules
    run_pipeline
    ;;
  *)
    echo 'usage: isoquant-smoke.sh [identity|modules|pipeline|buildtime|all]' >&2
    exit 2
    ;;
esac
