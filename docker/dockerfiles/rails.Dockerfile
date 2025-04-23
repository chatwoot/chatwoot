# Start from your base image
FROM courier-production-v1:latest

# Set working directory
WORKDIR /app

# Install Rails dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Install pnpm (for Vite)
RUN npm install -g pnpm

# Install frontend dependencies (Vite, etc.)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# Copy the rest of the application code
COPY . .

# Ensure entrypoint is executable
RUN chmod +x docker/entrypoints/rails.sh

# Expose ports
EXPOSE 3000

# Default command to start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]