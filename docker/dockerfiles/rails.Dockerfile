FROM courier-production-v1:latest

ARG SECRET_KEY_BASE
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE \
    RAILS_ENV=production \
    NODE_ENV=production \
    VITE_RUBY_AUTO_BUILD=false

WORKDIR /app

# Ensure required directories exist
RUN mkdir -p /app/public/vite

# Ensure entrypoint is executable
RUN chmod +x docker/entrypoints/rails.sh

EXPOSE 3000

CMD ["docker/entrypoints/rails.sh"]
