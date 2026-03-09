#!/usr/bin/env ruby

require_relative '/app/config/environment'

puts "🔍 DEBUG: Encontrando o erro 'to_hash'"
puts "=" * 40

# Classe simples para teste
class TestFile
  attr_reader :size, :content_type
  
  def initialize(file_path)
    @path = file_path
    @size = File.size(file_path)
    @content_type = 'image/webp'
  end
  
  def read
    File.binread(@path)
  end
  
  def rewind
  end
  
  def respond_to?(method)
    [:read, :rewind, :size, :content_type].include?(method)
  end
end

test_file = TestFile.new('app/uploaders/teste-stiker.webp')
puts "✅ File created successfully"

begin
  service = StickerImageOptimizerService.new(file: test_file, account_id: 1)
  puts "✅ Service created successfully"
  
  # Testar validações step by step
  puts "🔍 Testing input validation..."
  service.send(:validate_input!)
  puts "✅ Input validation passed"
  
  puts "🔍 Testing dependencies validation..."
  service.send(:validate_system_dependencies!)
  puts "✅ Dependencies validation passed"
  
  puts "🔍 Testing optimize_image_with_in_memory_architecture..."
  result = service.send(:optimize_image_with_in_memory_architecture)
  puts "✅ In-memory architecture completed"
  puts "Result keys: #{result.keys.inspect}"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts "📍 Class: #{e.class.name}"
  puts "📋 Backtrace:"
  e.backtrace.first(10).each { |line| puts "  #{line}" }
end
