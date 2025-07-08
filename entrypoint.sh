#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails
rm -f /app/tmp/pids/server.pid

# Wait for the database to be ready
until PGPASSWORD=$DB_PASSWORD psql -h db -U $DB_USER -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"

# Run pending migrations
bundle exec rails db:migrate

# Then exec the container's main process (what's set as CMD in the Dockerfile)
exec "$@"
