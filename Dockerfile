FROM rocker/r-ver:4.5.2

# setup for `rv` and R packages
# libglpk-dev is for `targets`
RUN apt update && \
    apt install -y --no-install-recommends \ 
    curl ca-certificates libglpk-dev && \
    rm -rf /var/lib/apt/lists/*

# install `rv`
# move from default ~/.local/bin/rv to /usr/local/bin/rv
RUN curl -sSL https://raw.githubusercontent.com/A2-ai/rv/refs/heads/main/scripts/install.sh \
    | bash -s -- --verbose || (echo "rv install failed" >&2; exit 1) && \
    mkdir -p /root/.local/bin && \
    mv /root/.local/bin/rv /usr/local/bin/rv && \
    chmod +x /usr/local/bin/rv
ENV PATH="/usr/local/bin:${PATH}"

# set work dir
WORKDIR /dart-forecasting

# load `rv`
COPY . .
RUN rv sync

