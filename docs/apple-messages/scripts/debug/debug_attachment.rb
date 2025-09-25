#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

attachment = Attachment.find(60)
puts "Attachment ID: #{attachment.id}"
puts "File attached: #{attachment.file.present?}"
if attachment.file.present?
  puts "Blob analyzed: #{attachment.file.blob.analyzed?}"
  puts "Blob metadata: #{attachment.file.blob.metadata}"
  puts "Width from metadata: #{attachment.file.metadata[:width]}"
  puts "Height from metadata: #{attachment.file.metadata[:height]}"
end
puts "File size: #{attachment.file.byte_size}"
puts "File type: #{attachment.file_type}"
puts "Extension: #{attachment.extension}"