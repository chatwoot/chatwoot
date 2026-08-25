# Overlays the MU changes onto the official Chatwoot image.
#
# Everything this fork adds is backend code plus static files under public/, so there
# is nothing to compile here — the build is a few COPY layers and finishes in seconds.
# Rebuild it whenever the fork changes or the base version moves.
#
#   docker build --build-arg CHATWOOT_VERSION=v4.17.0 \
#     -f docker/Dockerfile.mu -t mu-support/chatwoot:v4.17.0 .

ARG CHATWOOT_VERSION=v4.17.0
FROM chatwoot/chatwoot:${CHATWOOT_VERSION}

# apps.yml and en.yml are copied whole. A checkout that does not match the base image
# would quietly roll every other integration's config back to whatever this branch holds,
# so refuse to build instead.
COPY VERSION_CW /tmp/checkout_version
RUN if [ "$(cat /tmp/checkout_version)" != "$(cat /app/VERSION_CW)" ]; then \
      echo "checkout is $(cat /tmp/checkout_version) but the base image is $(cat /app/VERSION_CW); rebase the branch before building" >&2; \
      exit 1; \
    fi; \
    rm /tmp/checkout_version

COPY config/integration/apps.yml    /app/config/integration/apps.yml
COPY config/locales/en.yml          /app/config/locales/en.yml
COPY app/listeners/hook_listener.rb /app/app/listeners/hook_listener.rb
COPY app/jobs/hook_job.rb           /app/app/jobs/hook_job.rb
COPY lib/integrations/lark          /app/lib/integrations/lark
COPY public/dashboard/images/integrations/lark.png      /app/public/dashboard/images/integrations/lark.png
COPY public/dashboard/images/integrations/lark-dark.png /app/public/dashboard/images/integrations/lark-dark.png
