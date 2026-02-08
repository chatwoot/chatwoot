#!/usr/bin/env ruby

puts 'Testing StickerImageOptimizerService with 200.webp'
puts "File size: #{File.size('app/uploaders/200.webp')} bytes"

# Test optimization directly
service = StickerImageOptimizerService.new(file: 'app/uploaders/200.webp')
puts "Starting optimization..."
output_path = service.optimize_for_whatsapp('app/uploaders/200.webp')
puts "Output file: #{output_path}"

# Check if optimized version is still animated
if File.exist?(output_path)
  output_size = File.size(output_path)
  puts "Optimized size: #{output_size} bytes"
  puts "Checking optimized file frames:"
  system("identify '#{output_path}'")
end
