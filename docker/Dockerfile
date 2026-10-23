# The digest pins base contents, not permanent registry availability. If missing,
# verify the official Python image and revalidate a new immutable app release.
FROM python:3.12-slim-bookworm@sha256:782412e85d0f0984994c290652577d4018aff08145c85b262bb63dc0c7522254 AS builder

# Release assets can disappear; check the official tag/asset identity on 404 or
# checksum failure. Do not bypass verification or silently substitute latest.
ARG ISOQUANT_VERSION=4.1.0
ARG ISOQUANT_TARBALL_URL=https://github.com/ablab/IsoQuant/releases/download/v4.1.0/IsoQuant-4.1.0.tar.gz
ARG ISOQUANT_TARBALL_SHA256=04bdc504ae63bdf777aac4dc04109b60f477ea4d157ff928a96c784a12d968da

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONNOUSERSITE=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV ISOQUANT_PYTHON=/opt/isoquant/python
ENV PYTHONPATH=/opt/isoquant/python/lib/python3.12/site-packages
ENV PATH=/opt/isoquant/python/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

# Debian repositories are mutable: transitive versions can drift or disappear.
# On apt failure, inspect bookworm availability; revalidate both architectures
# before recording changed dependencies in a new app release.
RUN set -eux; \
    for attempt in 1 2 3 4 5; do \
      if apt-get -o Acquire::Retries=3 update \
       && apt-get -o Acquire::Retries=3 install -y --no-install-recommends \
            build-essential \
            ca-certificates \
            curl \
            patch \
            python3-dev \
            tar; then \
        break; \
      fi; \
      if [ "${attempt}" = "5" ]; then exit 1; fi; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*; \
      sleep 5; \
    done; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/isoquant-build

COPY docker/requirements.lock /tmp/isoquant-requirements.lock
COPY docker/patches/0001-store-generated-fai-in-output.patch /tmp/isoquant-fai.patch
COPY docker/patches/0002-honor-xdg-config-home.patch /tmp/isoquant-xdg.patch

# requirements.lock pins package versions, not PyPI retention or artifact bytes.
# If a wheel/sdist disappears or a resolver fails, inspect the official package
# and native-platform availability; do not silently relax the dependency lock.
RUN set -eux; \
    curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL "${ISOQUANT_TARBALL_URL}" -o isoquant.tar.gz; \
    echo "${ISOQUANT_TARBALL_SHA256}  isoquant.tar.gz" | sha256sum -c -; \
    mkdir -p src; \
    tar -xzf isoquant.tar.gz -C src --strip-components=1; \
    test "$(cat src/VERSION)" = "${ISOQUANT_VERSION}"; \
    echo '22c8c901dcca3142ed02e237d23e0dd97287bc1079ce0af564b104f0badbf7d4  /tmp/isoquant-fai.patch' | sha256sum -c -; \
    patch --batch -d src -p1 < /tmp/isoquant-fai.patch; \
    echo '59f4d0034d8b782a248ed1df61b2b771fea74e66cbb9a1f3d728f96d29b212a7  src/isoquant.py' | sha256sum -c -; \
    echo '03d60b6eb46d5b74dead6c38402a9429a6611bcf4238079c0a390d4a06bd824e  /tmp/isoquant-xdg.patch' | sha256sum -c -; \
    patch --batch -d src -p1 < /tmp/isoquant-xdg.patch; \
    echo 'b8da182cb032fa3a79039d0b09a2136b10ac12ef663c8fdcf802c55933e7c740  src/isoquant.py' | sha256sum -c -; \
    python -m venv "${ISOQUANT_PYTHON}"; \
    python -m pip install --no-cache-dir \
      "pip==26.0.1" \
      "setuptools==74.1.3" \
      "wheel==0.45.1"; \
    python -m pip install --no-cache-dir -r /tmp/isoquant-requirements.lock; \
    python -m pip install --no-cache-dir --no-deps --no-build-isolation ./src

RUN set -eux; \
    mkdir -p \
      /opt/isoquant/share/doc/isoquant/manual \
      /opt/isoquant/share/licenses/isoquant \
      /opt/isoquant/share/testdata; \
    cp src/LICENSE src/GPL2.txt /opt/isoquant/share/licenses/isoquant/; \
    cp src/README.md src/changelog.md src/VERSION /opt/isoquant/share/doc/isoquant/; \
    cp -a src/docs/. /opt/isoquant/share/doc/isoquant/manual/; \
    printf '%s\n' \
      "IsoQuant ${ISOQUANT_VERSION} packaged for TAFFISH from the official GitHub release asset." \
      "Base image: python:3.12-slim-bookworm@sha256:782412e85d0f0984994c290652577d4018aff08145c85b262bb63dc0c7522254" \
      "Source: ${ISOQUANT_TARBALL_URL}" \
      "SHA256: ${ISOQUANT_TARBALL_SHA256}" \
      "TAFFISH patch SHA256: 22c8c901dcca3142ed02e237d23e0dd97287bc1079ce0af564b104f0badbf7d4 (copy/rebuild pyfaidx FAI in the output directory without modifying the input)" \
      "TAFFISH patch SHA256: 03d60b6eb46d5b74dead6c38402a9429a6611bcf4238079c0a390d4a06bd824e (honor XDG_CONFIG_HOME for the IsoQuant path registry)" \
      "Patched isoquant.py SHA256: b8da182cb032fa3a79039d0b09a2136b10ac12ef663c8fdcf802c55933e7c740" \
      "Python: 3.12" \
      "XGBoost runtime: xgboost-cpu 2.1.4; IsoQuant uses CPU model inference and exposes no GPU-only analysis mode." \
      "Scikit-learn runtime: 1.7.2; newer 1.9 releases removed the estimator API used by XGBoost 2.1.4 model loading." \
      "XGBoost system runtime: Debian libtbb12 is included for the x86_64 xgboost-cpu wheel; the aarch64 wheel does not link it." \
      "External aligners: Debian bookworm minimap2, samtools, STAR, and STARlong are installed in the runtime stage." \
      > /opt/isoquant/share/doc/isoquant/source.txt; \
    python <<'PY' > /opt/isoquant/share/doc/isoquant/python-packages.txt
import importlib.metadata as md

rows = []
for dist in md.distributions():
    name = dist.metadata.get("Name")
    if name:
        rows.append((name.lower(), f"{name}=={dist.version}"))
for _, row in sorted(rows):
    print(row)
PY

RUN set -eux; \
    find "${ISOQUANT_PYTHON}" -type d -name '__pycache__' -prune -exec rm -rf '{}' +; \
    find "${ISOQUANT_PYTHON}" -type d \( -name 'tests' -o -name 'test' -o -name 'benchmarks' \) -prune -exec rm -rf '{}' +; \
    find "${ISOQUANT_PYTHON}" -type f \( -name '*.pyc' -o -name '*.pyo' -o -name '*.a' \) -delete; \
    site_packages="${ISOQUANT_PYTHON}/lib/python3.12/site-packages"; \
    rm -rf \
      "${site_packages}"/pip \
      "${site_packages}"/pip-*.dist-info \
      "${site_packages}"/wheel \
      "${site_packages}"/wheel-*.dist-info; \
    rm -f "${ISOQUANT_PYTHON}"/bin/pip "${ISOQUANT_PYTHON}"/bin/pip3 "${ISOQUANT_PYTHON}"/bin/pip3.12; \
    rm -rf /root/.cache /tmp/isoquant-build /tmp/isoquant-requirements.lock /tmp/isoquant-fai.patch /tmp/isoquant-xdg.patch

FROM python:3.12-slim-bookworm@sha256:782412e85d0f0984994c290652577d4018aff08145c85b262bb63dc0c7522254 AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONNOUSERSITE=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV MPLBACKEND=Agg
ENV HOME=/tmp/isoquant-home
ENV MPLCONFIGDIR=/tmp/matplotlib
ENV NUMBA_CACHE_DIR=/tmp/numba-cache
ENV XDG_CACHE_HOME=/tmp/xdg-cache
ENV XDG_CONFIG_HOME=/tmp/xdg-config
ENV XDG_DATA_HOME=/tmp/xdg-data
ENV PYTHONPATH=/opt/isoquant/python/lib/python3.12/site-packages
ENV PATH=/opt/isoquant/python/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

# The same mutable Debian-repository boundary applies to runtime packages.
# Keep architecture-specific runtime dependencies; recheck ldd and real tools.
RUN set -eux; \
    tbb_runtime=''; \
    if [ "$(dpkg --print-architecture)" = 'amd64' ]; then \
      tbb_runtime='libtbb12'; \
    fi; \
    for attempt in 1 2 3 4 5; do \
      if apt-get -o Acquire::Retries=3 update \
       && apt-get -o Acquire::Retries=3 install -y --no-install-recommends \
            bash \
            bzip2 \
            ca-certificates \
            coreutils \
            findutils \
            fonts-dejavu-core \
            grep \
            gzip \
            libgomp1 \
            libstdc++6 \
            ${tbb_runtime} \
            minimap2 \
            rna-star \
            samtools \
            sed \
            xz-utils \
            zlib1g; then \
        break; \
      fi; \
      if [ "${attempt}" = "5" ]; then exit 1; fi; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*; \
      sleep 5; \
    done; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY --from=builder /opt/isoquant /opt/isoquant
COPY docker/isoquant-smoke.sh /opt/isoquant/share/testdata/isoquant-smoke.sh

RUN set -eux; \
    dpkg-query -W -f='${Package}==${Version}\n' | sort > /opt/isoquant/share/doc/isoquant/debian-packages.txt

FROM runtime AS final

# Build-time checks stay lightweight on both native architectures. Full analysis,
# loom export and browser/report rendering belong to independent offline tests.

RUN set -eux; \
    chmod 0755 /opt/isoquant/share/testdata/isoquant-smoke.sh; \
    /opt/isoquant/share/testdata/isoquant-smoke.sh buildtime; \
    find /opt/isoquant/python -type f -name '*.so' -print0 | xargs -0 -r ldd > /tmp/isoquant-ldd.txt; \
    if grep -F 'not found' /tmp/isoquant-ldd.txt; then exit 1; fi; \
    rm -rf \
      /tmp/isoquant-ldd.txt \
      /tmp/matplotlib \
      /tmp/numba-cache \
      /tmp/xdg-cache \
      /tmp/xdg-config \
      /tmp/xdg-data \
      /root/.cache

WORKDIR /root

ENV TAFFISH_ENV=TAFFISH
ENV TAFFISH_NAME=isoquant
