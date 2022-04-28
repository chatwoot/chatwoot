#!/usr/bin/env ruby
require 'uri'

# Let DATABASE_URL env take presedence over individual connection params.
if !ENV['DATABASE_URL'].nil? && ENV.fetch('DATABASE_URL', nil) != ''
  uri = URI(ENV.fetch('DATABASE_URL', nil))
  puts "export POSTGRES_HOST=#{uri.host} POSTGRES_PORT=#{uri.port} POSTGRES_USERNAME=#{uri.user}"
elsif ENV['POSTGRES_PORT'].nil? || ENV.fetch('POSTGRES_PORT', nil) == ''
  puts 'export POSTGRES_PORT=5432'
end
