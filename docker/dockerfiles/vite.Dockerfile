FROM chatwoot:development

ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# 🔧 Install correct bundler version
RUN gem install bundler -v '2.5.11'

# 🛠 Make entrypoint executable
RUN chmod +x docker/entrypoints/vite.sh

EXPOSE 3036

# 🚀 Start the vite dev server
CMD ["bin/vite", "dev"]
