# Use your project's base image instead of chatwoot
FROM courier-production-v1:latest

# Set environment variables for Vite
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Ensure that the entrypoint script is executable
RUN chmod +x docker/entrypoints/vite.sh

# Expose the Vite dev server port
EXPOSE 3036

# Run the Vite dev server command
CMD ["bin/vite", "dev"]