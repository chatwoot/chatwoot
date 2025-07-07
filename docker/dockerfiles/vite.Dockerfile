FROM ruby:3.4.4-bullseye

ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

COPY docker/entrypoints/vite.sh docker/entrypoints/vite.sh
RUN chmod +x docker/entrypoints/vite.sh

EXPOSE 3036
CMD ["bin/vite", "dev"]
