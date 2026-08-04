FROM python:3.12-slim-bookworm AS builder

ARG ISOQUANT_VERSION=4.0.0
ARG ISOQUANT_TARBALL_URL=https://github.com/ablab/IsoQuant/releases/download/v4.0.0/IsoQuant-4.0.0.tar.gz
ARG ISOQUANT_TARBALL_SHA256=98fbe5b2f9c39c9cc52041b106f06e6f11bbf9c75c500b44505e973805ed0921

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONNOUSERSITE=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV ISOQUANT_PYTHON=/opt/isoquant/python
ENV PYTHONPATH=/opt/isoquant/python/lib/python3.12/site-packages
ENV PATH=/opt/isoquant/python/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN set -eux; \
    for attempt in 1 2 3 4 5; do \
      if apt-get -o Acquire::Retries=3 update \
       && apt-get -o Acquire::Retries=3 install -y --no-install-recommends \
            build-essential \
            ca-certificates \
            curl \
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

RUN set -eux; \
    curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL "${ISOQUANT_TARBALL_URL}" -o isoquant.tar.gz; \
    echo "${ISOQUANT_TARBALL_SHA256}  isoquant.tar.gz" | sha256sum -c -; \
    mkdir -p src; \
    tar -xzf isoquant.tar.gz -C src --strip-components=1; \
    test "$(cat src/VERSION)" = "${ISOQUANT_VERSION}"; \
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
      "Source: ${ISOQUANT_TARBALL_URL}" \
      "SHA256: ${ISOQUANT_TARBALL_SHA256}" \
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
      "${site_packages}"/setuptools \
      "${site_packages}"/setuptools-*.dist-info \
      "${site_packages}"/wheel \
      "${site_packages}"/wheel-*.dist-info; \
    rm -f "${ISOQUANT_PYTHON}"/bin/pip "${ISOQUANT_PYTHON}"/bin/pip3 "${ISOQUANT_PYTHON}"/bin/pip3.12; \
    rm -rf /root/.cache /tmp/isoquant-build /tmp/isoquant-requirements.lock

FROM python:3.12-slim-bookworm AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONNOUSERSITE=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV MPLBACKEND=Agg
ENV MPLCONFIGDIR=/tmp/matplotlib
ENV NUMBA_CACHE_DIR=/tmp/numba-cache
ENV XDG_CACHE_HOME=/tmp/xdg-cache
ENV XDG_CONFIG_HOME=/tmp/xdg-config
ENV XDG_DATA_HOME=/tmp/xdg-data
ENV PYTHONPATH=/opt/isoquant/python/lib/python3.12/site-packages
ENV PATH=/opt/isoquant/python/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

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
