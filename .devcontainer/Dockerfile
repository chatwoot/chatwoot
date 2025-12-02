# The below image is created out of the Dockerfile.base
# It has the dependencies already installed so that codespace will boot up fast
FROM ghcr.io/chatwoot/chatwoot_codespace:latest

# Do the set up required for chatwoot app
WORKDIR /workspace

# Copy dependency files first for better caching
# -------------- Reason ---------------
# Fixes permission errors during bundle install by ensuring non-root user owns files
# ------------ Original -----------------------
# COPY package.json pnpm-lock.yaml ./
# COPY Gemfile Gemfile.lock ./
# ---------------------------------------------
# ---------------------- Modification Begin ----------------------
COPY --chown=vscode:vscode package.json pnpm-lock.yaml ./
COPY --chown=vscode:vscode Gemfile Gemfile.lock ./
# ---------------------- Modification End ------------------------

# Install dependencies (will be cached if files don't change)
RUN pnpm install --frozen-lockfile && \
    gem install bundler && \
    bundle install --jobs=$(nproc)
    
# Copy source code after dependencies are installed
COPY . /workspace
