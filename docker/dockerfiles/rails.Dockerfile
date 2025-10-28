FROM courier-production-v1:latest

ARG SECRET_KEY_BASE
ARG POSTMARK_API_TOKEN
ARG CDN_ACCESS_KEY
ARG CDN_ACCESS_SECRET
ARG CDN_REGION
ARG CDN_BUCKET
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE \
    POSTMARK_API_TOKEN=$POSTMARK_API_TOKEN \
    RAILS_ENV=production \
    NODE_ENV=production \
    VITE_RUBY_AUTO_BUILD=false \
    SOURCE_TOKEN=$SOURCE_TOKEN \
    INGESTING_HOST=$INGESTING_HOST \
    CDN_ACCESS_KEY=$CDN_ACCESS_KEY \
    CDN_ACCESS_SECRET=$CDN_ACCESS_SECRET \
    CDN_REGION=$CDN_REGION \
    CDN_BUCKET=$CDN_BUCKET


WORKDIR /app

# Ensure required directories exist
RUN mkdir -p /app/public/vite

# Ensure entrypoint is executable
RUN chmod +x docker/entrypoints/rails.sh

# Precompile assets
# RUN if [ "$RAILS_ENV" = "production" ]; then \
#     NODE_OPTIONS="--max-old-space-size=8192" \
#     bundle exec rake assets:precompile && \
#     rm -rf spec node_modules tmp/cache /root/.cache /root/.npm; \
# fi

EXPOSE 3000

CMD ["docker/entrypoints/rails.sh"]