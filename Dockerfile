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

# Copy Gemfile and Gemfile.lock (if they exist)
COPY Gemfile* ./

# Install gems
RUN bundle install

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Start the Rails server
CMD ["rails", "server", "-b", "0.0.0.0"]
