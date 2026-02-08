#!/usr/bin/env ruby

require_relative 'config/environment'

# Configurar o nível de log para INFO para ver tudo
Rails.logger.level = Logger::INFO

input_file = "/app/app/uploaders/love.webp"
output_file = "/app/optimized_with_logs.webp"

puts "🚀 TESTE COM LOGS DETALHADOS"
puts "=============================="
puts "📁 Entrada: #{input_file}"
puts "📁 Saída: #{output_file}"

begin
  result = StickerImageOptimizerService.optimize_sticker(input_file, output_file)
  puts "\n✅ Resultado: #{result}"
  
  if File.exist?(output_file)
    puts "📊 Tamanho gerado: #{File.size(output_file)} bytes"
  else
    puts "❌ Arquivo de saída não foi criado!"
  end
  
rescue => e
  puts "\n❌ Erro: #{e.class.name}: #{e.message}"
  e.backtrace.first(5).each { |line| puts "  #{line}" }
end
