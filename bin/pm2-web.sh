#!/bin/bash
cd /home/deltatec/develop/chatwoot
bundle exec rails ip_lookup:setup
exec bin/rails server -b 0.0.0.0 -p ${PORT:-3000} -e ${RAILS_ENV:-development}

