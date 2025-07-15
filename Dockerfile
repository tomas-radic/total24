FROM ruby:3.3.6-slim

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    nodejs \
    npm \
    postgresql-client \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock first (for better Docker layer caching)
COPY Gemfile* ./

# Install gems
RUN bundle install

# Copy the rest of the application code
COPY . .

# Precompile assets for production
RUN RAILS_ENV=production bundle exec rails assets:precompile

# Create a non-root user
RUN groupadd -r rails && useradd -r -g rails rails
RUN chown -R rails:rails /app
USER rails

# Expose port
EXPOSE 3000

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-e", "production"]
