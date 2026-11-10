# Stage 1: Build gems using the full Ruby 3.3 image
FROM ruby:3.3 AS builder

WORKDIR /app

# Set production environment and skip dev/test gems
ENV RAILS_ENV="production" \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH="/usr/local/bundle"

# Copy Gemfile first so Docker caches installed gems
COPY Gemfile ./
RUN bundle install --jobs 4 --retry 3

# Copy the rest of the Rails app
COPY . .


# Stage 2: Final slim image for running the app
FROM ruby:3.3-slim AS runtime

WORKDIR /app

# Install libpq5 for PostgreSQL connection and libyaml/curl for Rails 8 and healthchecks
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libpq5 libyaml-0-2 curl && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ENV RAILS_ENV="production" \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH="/usr/local/bundle" \
    PORT="3000"

# Create a non-root user (rails) for security
RUN groupadd --system --gid 1000 rails && \
    useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash rails

# Copy compiled gems and app files from the builder stage
COPY --from=builder --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=rails:rails /app /app

# Make sure temp/log folders exist and entrypoint script can run
RUN mkdir -p /app/tmp/pids /app/log && \
    chown -R rails:rails /app/tmp /app/log && \
    chmod +x /app/bin/docker-entrypoint

# Switch from root to the rails user
USER rails

# Puma listens on port 3000
EXPOSE 3000

# Run db migrations on startup, then start Puma
ENTRYPOINT ["/app/bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
