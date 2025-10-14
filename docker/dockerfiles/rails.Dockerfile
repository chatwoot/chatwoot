FROM courier-production-v1:latest

ARG SECRET_KEY_BASE
ARG POSTMARK_API_TOKEN
ARG STORAGE_ACCESS_KEY_ID
ARG STORAGE_SECRET_ACCESS_KEY
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE \
    POSTMARK_API_TOKEN=$POSTMARK_API_TOKEN \
    RAILS_ENV=production \
    NODE_ENV=production \
    VITE_RUBY_AUTO_BUILD=false \
    SOURCE_TOKEN=$SOURCE_TOKEN \
    INGESTING_HOST=$INGESTING_HOST \
    STORAGE_ACCESS_KEY_ID=$STORAGE_ACCESS_KEY_ID \
    STORAGE_SECRET_ACCESS_KEY=$STORAGE_SECRET_ACCESS_KEY


WORKDIR /app

# Ensure required directories exist
RUN mkdir -p /app/public/vite

# Ensure entrypoint is executable
RUN chmod +x docker/entrypoints/rails.sh

# Precompile assets
RUN if [ "$RAILS_ENV" = "production" ]; then \
    NODE_OPTIONS="--max-old-space-size=8192" \
    bundle exec rake assets:precompile && \
    rm -rf spec node_modules tmp/cache /root/.cache /root/.npm; \
fi

EXPOSE 3000

CMD ["docker/entrypoints/rails.sh"]