#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🚀 DEBUG: Testando compensação de tempo"
puts "=" * 60

input_file = "/app/app/uploaders/love.webp"
output_file = "/tmp/love_optimized_debug.webp"

puts "📁 Arquivo: #{input_file}"
puts "📊 Tamanho original: #{File.size(input_file)} bytes"

begin
  # Testar diretamente o service
  optimizer = StickerImageOptimizerService.new(
    file: File.open(input_file, 'rb'),
    account_id: 1
  )
  
  result = optimizer.process
  
  puts "✅ Resultado: #{result.inspect}"
  
rescue => e
  puts "❌ Erro: #{e.class.name}: #{e.message}"
  puts "📋 Backtrace:"
  e.backtrace.first(10).each { |line| puts "  #{line}" }
end

puts "🏁 Debug finalizado!"
