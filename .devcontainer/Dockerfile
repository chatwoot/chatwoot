FROM ghcr.io/chatwoot/chatwoot_codespace:latest

USER vscode

# Do the set up required for chatwoot app
WORKDIR /workspace

# Copy dependency files with correct ownership
COPY --chown=vscode:vscode package.json pnpm-lock.yaml ./
COPY --chown=vscode:vscode Gemfile Gemfile.lock ./

# Install dependencies (will be cached if files don't change)
RUN pnpm install --frozen-lockfile && \
    gem install bundler && \
    bundle install --jobs=$(nproc)

# Copy source code after dependencies are installed
COPY . /workspace
