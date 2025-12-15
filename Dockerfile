# Multi-stage build for production

FROM ruby:3.3.6-slim AS builder

# Install build dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4

# Copy application
COPY . .

# Precompile assets
RUN SECRET_KEY_BASE=placeholder bundle exec rails assets:precompile

# Runtime stage
FROM ruby:3.3.6-slim

# Install runtime dependencies
RUN apt-get update -qq && apt-get install -y \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create non-root user
RUN groupadd -r rails && useradd -r -g rails rails

# Copy from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=rails:rails /app /app

# Switch to non-root user
USER rails

EXPOSE 3000

# Use Thruster for production
CMD ["bin/thrust", "./bin/rails", "server"]
