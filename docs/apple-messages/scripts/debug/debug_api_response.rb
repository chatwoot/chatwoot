#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

attachment = Attachment.find(60)
puts "=== Attachment API Response Debug ==="
puts "Attachment ID: #{attachment.id}"
puts "Push event data:"
puts attachment.push_event_data.inspect
puts ""
puts "File metadata:"
puts attachment.file_metadata.inspect
puts ""
puts "Base data:"
puts attachment.base_data.inspect