FROM rocker/r-ver:4.5.2

# setup for `rv` and R packages
RUN apt update && \
    apt install -y --no-install-recommends \ 
    curl ca-certificates git && \
    rm -rf /var/lib/apt/lists/*

# install `rv`
RUN curl -sSL https://raw.githubusercontent.com/A2-ai/rv/refs/heads/main/scripts/install.sh \
    | bash -s -- --verbose || \ 
    (echo "rv install failed" >&2; exit 1)
ENV PATH="/root/.local/bin:${PATH}"

# set work dir
WORKDIR /dart-forecasting
# copy over necessary rv stuff first
COPY rv /dart-forecasting/rv
COPY rproject.toml rv.lock .Rprofile /dart-forecasting/

# install sysdeps for R packages
RUN apt update 
RUN pkgs="$(rv sysdeps)" && \
    if [ -n "$pkgs" ]; then \
    apt-get install -y --no-install-recommends $pkgs; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# sync `rv`
RUN rv sync

# copy rest of project
COPY target_fns /dart-forecasting/target_fns
COPY _targets.* /dart-forecasting/
COPY targets_*.R /dart-forecasting/


ENTRYPOINT [ "Rscript", "targets_runner.R" ]