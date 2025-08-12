# FassZap - Enterprise Customer Support Platform
# Based on Chatwoot with Enterprise features and Fabiana AI
FROM chatwoot/chatwoot:v3.12.0

# Set maintainer and labels
LABEL maintainer="FassZap Team"
LABEL description="FassZap - Enterprise Customer Support Platform with Fabiana AI"
LABEL version="1.0.0"

# Set environment variables for FassZap
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV CW_EDITION=enterprise
ENV INSTALLATION_PRICING_PLAN=enterprise
ENV INSTALLATION_PRICING_PLAN_QUANTITY=10

# Set working directory
WORKDIR /app

# Copy all FassZap modifications
COPY . /tmp/fasszap-src/

# Apply FassZap modifications (as root to avoid permission issues)
USER root
RUN cp -f /tmp/fasszap-src/config/installation_config.yml config/ || true && \
    cp -f /tmp/fasszap-src/lib/chatwoot_hub.rb lib/ || true && \
    cp -f /tmp/fasszap-src/lib/chatwoot_app.rb lib/ || true && \
    cp -f /tmp/fasszap-src/public/manifest.json public/ || true && \
    cp -f /tmp/fasszap-src/theme/colors.js theme/ || true && \
    mkdir -p app/assets/stylesheets/administrate/utilities && \
    mkdir -p app/assets/stylesheets/administrate/library && \
    cp -f /tmp/fasszap-src/app/assets/stylesheets/administrate/utilities/_variables.scss app/assets/stylesheets/administrate/utilities/ || true && \
    cp -f /tmp/fasszap-src/app/assets/stylesheets/administrate/library/_variables.scss app/assets/stylesheets/administrate/library/ || true && \
    mkdir -p app/helpers/super_admin && \
    cp -f /tmp/fasszap-src/app/helpers/super_admin/features.yml app/helpers/super_admin/ || true && \
    mkdir -p enterprise/config && \
    cp -f /tmp/fasszap-src/enterprise/config/premium_features.yml enterprise/config/ || true && \
    cp -f /tmp/fasszap-src/enterprise/config/premium_installation_config.yml enterprise/config/ || true && \
    mkdir -p enterprise/app/services/llm && \
    cp -f /tmp/fasszap-src/enterprise/app/services/llm/base_open_ai_service.rb enterprise/app/services/llm/ || true

# Copy FassZap specific files
RUN mkdir -p config/initializers && \
    mkdir -p enterprise/app/services/fabiana && \
    mkdir -p enterprise/app/controllers/api/v1/accounts/fabiana && \
    mkdir -p db/migrate && \
    mkdir -p bin && \
    cp -f /tmp/fasszap-src/config/initializers/fasszap_enterprise.rb config/initializers/ || true && \
    cp -r /tmp/fasszap-src/enterprise/app/services/fabiana/* enterprise/app/services/fabiana/ 2>/dev/null || true && \
    cp -r /tmp/fasszap-src/enterprise/app/controllers/api/v1/accounts/fabiana/* enterprise/app/controllers/api/v1/accounts/fabiana/ 2>/dev/null || true && \
    cp -f /tmp/fasszap-src/db/migrate/20241212000001_enable_fasszap_enterprise.rb db/migrate/ || true && \
    cp -f /tmp/fasszap-src/bin/fasszap_setup bin/ || true && \
    cp -f /tmp/fasszap-src/bin/fasszap_test bin/ || true

# Make scripts executable and fix permissions
RUN chmod +x bin/fasszap_setup bin/fasszap_test 2>/dev/null || true && \
    chown -R app:app /app && \
    rm -rf /tmp/fasszap-src

# Switch back to app user
USER app

# Create FassZap startup script
RUN echo '#!/bin/bash\n\
echo "🧡 Starting FassZap - Enterprise Customer Support Platform"\n\
echo "🤖 With Fabiana AI (OpenAI, ChatGPT, Groq support)"\n\
echo ""\n\
# Wait for database\n\
echo "⏳ Waiting for database connection..."\n\
while ! pg_isready -h ${POSTGRES_HOST:-db} -U ${POSTGRES_USERNAME:-postgres} -q; do\n\
  echo "Database not ready, waiting..."\n\
  sleep 2\n\
done\n\
echo "✅ Database connected"\n\
\n\
# Prepare database\n\
echo "🗄️ Preparing database..."\n\
bundle exec rails db:chatwoot_prepare\n\
\n\
# Run FassZap setup\n\
echo "⚙️ Running FassZap enterprise setup..."\n\
if [ -f "./bin/fasszap_setup" ]; then\n\
  ./bin/fasszap_setup\n\
else\n\
  echo "⚠️ FassZap setup script not found, using fallback configuration"\n\
fi\n\
\n\
# Start the server\n\
echo "🚀 Starting FassZap server on port 3000..."\n\
echo "🌐 Access your FassZap instance at: ${FRONTEND_URL:-http://localhost:3000}"\n\
echo ""\n\
bundle exec rails server -b 0.0.0.0 -p 3000' > /app/start_fasszap.sh

RUN chmod +x /app/start_fasszap.sh

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:3000/api/v1/accounts || exit 1

# Set default command
CMD ["/app/start_fasszap.sh"]
