#!/bin/bash
pids=( $! )

# Start the nuxt server
npm run dev &
pids+=( $! )

# Run the cypress tests
echo "⏳ Waiting for server to boot..."
npx wait-on http://localhost:7872
echo "✅ Server booted."
echo "Running cypress tests..."

npx cypress run --record --key $CYPRESS_KEY
# Store the exit code for later
status=$?

# Shutdown all background jobs
for pid in ${pids[@]}; do
  echo "Shutting down process $pid"
  kill $pid
done
# Shutdown with the status of our tests
exit $status
