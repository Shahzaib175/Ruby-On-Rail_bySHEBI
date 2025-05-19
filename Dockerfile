# syntax=docker/dockerfile:1
# check=error=true

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app directory inside container
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set development environment variables
ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle"

# Build stage to compile gems and assets
FROM base AS build

# Install build dependencies for gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy Gemfiles and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile || true

# Copy the full app source code
COPY . .

# Precompile bootsnap caches (optional in dev, fallback if fails)
RUN bundle exec bootsnap precompile app/ lib/ || true

# Final image stage
FROM base

# Copy gems and app from build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create non-root user 'rails' and assign ownership of runtime directories
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER 1000:1000

# Optional: skip entrypoint if not needed
# ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Expose development port
EXPOSE 3000

# Start Rails server in development mode
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
