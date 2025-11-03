FROM chatwoot:development

ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN gem install bundler -v '2.5.16' --no-document

RUN chmod +x docker/entrypoints/vite.sh

EXPOSE 3036
CMD ["bin/vite", "dev"]
