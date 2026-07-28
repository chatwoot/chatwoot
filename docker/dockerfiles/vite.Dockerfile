# Parameterised so the fork can build/tag its own base image without diverging
# from upstream's default. Compose passes BASE_IMAGE=mesh-crm:development.
ARG BASE_IMAGE=chatwoot:development
FROM ${BASE_IMAGE}

ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN chmod +x docker/entrypoints/vite.sh

EXPOSE 3036
CMD ["bin/vite", "dev"]
