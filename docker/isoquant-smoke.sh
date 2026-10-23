#!/bin/sh
set -eu

mode="${1:-all}"

say() {
  printf 'isoquant-smoke: %s\n' "$*" >&2
}

run_identity() {
  say "identity"
  isoquant --version 2>&1 | grep -Fx 'IsoQuant 4.1.0' >/dev/null
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
import h5py
import loompy
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

assert md.version("isoquant") == "4.1.0"
assert md.version("loompy") == "3.0.8"
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

run_loom() {
  say "upstream-loom-export"
  python - <<'PY'
import tempfile
from types import SimpleNamespace
from pathlib import Path
import pandas as pd
import loompy
from isoquant_lib.quantification.rna_velocity_counter import RNAVelocityCounter

# Exercise the actual upstream exporter with synthetic non-biological counts.
with tempfile.TemporaryDirectory(prefix="isoquant-loom-") as root:
    prefix = str(Path(root) / "counts")
    counts = pd.DataFrame({"gene_id": ["gene1", "gene2", "gene1"],
                          "cell_id": ["cell1", "cell2", "cell1"],
                          "spliced": [2, 3, 4], "unspliced": [1, 0, 2],
                          "ambiguous": [0, 1, 0]})
    RNAVelocityCounter(SimpleNamespace(), prefix).create_loom(counts)
    with loompy.connect(prefix + ".loom", mode="r") as ds:
        assert ds.shape == (2, 2)
        assert set(ds.layers.keys()) == {"", "spliced", "unspliced", "ambiguous"}
        assert list(ds.ra.Gene) == ["gene1", "gene2"]
        assert list(ds.ca.CellID) == ["cell1", "cell2"]
        assert ds.layers["spliced"][:, :].tolist() == [[6, 0], [0, 3]]
        assert ds.layers["unspliced"][:, :].sum() == 3
        assert ds.layers["ambiguous"][:, :].sum() == 1
PY
}

run_pipeline() {
  say "upstream-toy-pipeline"
  tmp="$(mktemp -d /tmp/taf-isoquant-pipeline.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  cd "$tmp"
  if isoquant --test > run.log 2>&1; then
    :
  else
    status=$?
    say "stage=isoquant-test exit=$status"
    tail -n 200 run.log >&2
    exit "$status"
  fi
  if grep -E 'CRITICAL|Traceback|=== TEST FAILED ===' run.log >/dev/null; then
    say "stage=isoquant-test validation=critical-log"
    tail -n 200 run.log >&2
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
  if isoquant-visualize isoquant_test \
      --gene_list /dev/null \
      --find_genes 1 \
      --viz_output visualization > visualization.log 2>&1; then
    :
  else
    status=$?
    say "stage=visualization exit=$status"
    tail -n 200 visualization.log >&2
    exit "$status"
  fi
  if grep -E 'CRITICAL|Traceback' visualization.log >/dev/null; then
    say "stage=visualization validation=critical-log"
    tail -n 200 visualization.log >&2
    exit 1
  fi
  test -s visualization/combined_visualization.png
  test -s visualization/read_assignment_consistency_pie_chart.png
  test -s visualization/top_1_genes.txt
  python - <<'PY'
from pathlib import Path
import json
from html.parser import HTMLParser

report = Path("isoquant_test/TEST_DATA/TEST_DATA.summary.html")
stats = report.with_name("TEST_DATA.summary_stats.json")
assert isinstance(json.loads(stats.read_text()), dict)
text = report.read_text()
assert "IsoQuant" in text and "<svg" in text and "</html>" in text
class OfflineCheck(HTMLParser):
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in {"script", "img", "iframe", "link", "object", "embed"}:
            for key in ("src", "href", "data"):
                url = attrs.get(key, "")
                assert not url or url.startswith(("data:", "#")), (tag, url)
OfflineCheck().feed(text)
PY
  rm -rf "$tmp"
}

case "$mode" in
  identity) run_identity ;;
  modules) run_modules ;;
  loom) run_loom ;;
  pipeline) run_pipeline ;;
  buildtime)
    run_identity
    run_modules
    ;;
  all)
    run_identity
    run_modules
    run_loom
    run_pipeline
    ;;
  *)
    echo 'usage: isoquant-smoke.sh [identity|modules|loom|pipeline|buildtime|all]' >&2
    exit 2
    ;;
esac
