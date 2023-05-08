#!/bin/bash

# Sidekiq main process
bundle exec sidekiq -C config/sidekiq.yml & 

# Rails server second process for health check
bundle exec rails s -p 3000 -b 0.0.0.0 &
  
# Wait for any process to exit
wait -n
  
# Exit with status of process that exited first
exit $?