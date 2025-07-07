FROM ruby:3.4.4-bullseye

ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# 🧩 Instala postgresql-client para pg_isready
RUN apt-get update && apt-get install -y --no-install-recommends postgresql-client \
  && rm -rf /var/lib/apt/lists/*

# 🧩 Copia los entrypoints
COPY docker/entrypoints/rails.sh docker/entrypoints/rails.sh
COPY docker/entrypoints/vite.sh docker/entrypoints/vite.sh

# 🧩 Copia el helper pg_database_url.rb
RUN mkdir -p docker/entrypoints/helpers
COPY docker/entrypoints/helpers/pg_database_url.rb docker/entrypoints/helpers/pg_database_url.rb

# 🧩 Permisos de ejecución
RUN chmod +x docker/entrypoints/rails.sh
RUN chmod +x docker/entrypoints/vite.sh

# Entrypoint
ENTRYPOINT ["docker/entrypoints/rails.sh"]

EXPOSE 3000

