# ==========================================
# Stage 1: Build Stage
# ==========================================
FROM ruby:3.3 AS builder

WORKDIR /app

# Configure bundler for production
ENV RAILS_ENV="production" \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH="/usr/local/bundle"

# Install gems first to leverage Docker layer caching
COPY Gemfile ./
RUN bundle install --jobs 4 --retry 3

# Copy the rest of the application source code
COPY . .

# ==========================================
# Stage 2: Runtime Stage (Minimal Image)
# ==========================================
FROM ruby:3.3-slim AS runtime

WORKDIR /app

# Install runtime dependencies:
# - libpq5 is required for the pg gem to communicate with PostgreSQL
# - curl is required for container health checks
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libpq5 curl && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ENV RAILS_ENV="production" \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH="/usr/local/bundle" \
    PORT="3000"

# Create a non-root user and group to run the application securely
RUN groupadd --system --gid 1000 rails && \
    useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash rails

# Copy installed gems and application code from the builder stage
COPY --from=builder --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=rails:rails /app /app

# Ensure required runtime directories exist and belong to the non-root user
RUN mkdir -p /app/tmp/pids /app/log && \
    chown -R rails:rails /app/tmp /app/log && \
    chmod +x /app/bin/docker-entrypoint

# Switch to the non-root user
USER rails

# Expose the Puma application port
EXPOSE 3000

ENTRYPOINT ["/app/bin/docker-entrypoint"]

# Start the Puma server shipped with Rails
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]