#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🚀 TESTE DA CORREÇÃO DE METADATA"
puts "=================================="

input_file = "/app/app/uploaders/love.webp"
output_file = "/app/optimized_metadata_test.webp"

puts "📁 Arquivo de entrada: #{input_file}"
puts "📊 Tamanho original: #{File.size(input_file)} bytes"

begin
  puts "\n🔧 Executando otimização..."
  result = StickerImageOptimizerService.optimize_sticker(input_file, output_file)
  
  if result && File.exist?(output_file)
    puts "✅ Otimização bem-sucedida!"
    puts "📊 Tamanho otimizado: #{File.size(output_file)} bytes"
    puts "📊 Redução: #{((File.size(input_file) - File.size(output_file)) / File.size(input_file).to_f * 100).round(2)}%"
  else
    puts "❌ Otimização falhou - resultado: #{result}"
  end
  
rescue => e
  puts "❌ Erro durante otimização: #{e.class.name}: #{e.message}"
  puts "🔍 Backtrace:"
  e.backtrace.first(10).each { |line| puts "  #{line}" }
end

puts "\n🏁 Teste finalizado!"
