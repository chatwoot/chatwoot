#!/usr/bin/env ruby
require 'uri'

# Let DATABASE_URL env take presedence over individual connection params.
if !ENV['DATABASE_URL'].nil? && ENV['DATABASE_URL'] != ''
  uri = URI(ENV['DATABASE_URL'])
  puts "export POSTGRES_HOST=#{uri.host} POSTGRES_PORT=#{uri.port} POSTGRES_USERNAME=#{uri.user}"
elsif ENV['POSTGRES_PORT'].nil? || ENV['POSTGRES_PORT'] == ''
  puts 'export POSTGRES_PORT=5432'
end
