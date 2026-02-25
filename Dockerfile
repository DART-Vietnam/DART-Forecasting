FROM rocker/r-ver:4.5.2

# setup for `rv` and R packages
RUN apt update && \
    apt install -y --no-install-recommends \ 
    curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# install `rv`
RUN curl -sSL https://raw.githubusercontent.com/A2-ai/rv/refs/heads/main/scripts/install.sh \
    | bash -s -- --verbose || \ 
    (echo "rv install failed" >&2; exit 1)
ENV PATH="/root/.local/bin:${PATH}"

# set work dir
WORKDIR /dart-forecasting
COPY . .

# install sysdeps for R packages
RUN apt update && \
    pkgs="$(rv sysdeps)" && \
    if [ -n "$pkgs" ]; then \
    apt-get install -y --no-install-recommends $pkgs; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# sync `rv`
RUN rv sync

ENTRYPOINT [ "Rscript", "target_runner.R" ]