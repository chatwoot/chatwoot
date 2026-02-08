#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

# === TESTE COMPLETO COM CÓDIGO ATUAL ===
puts '🎬 Testando StickerImageOptimizerService com arquivo real...'

# Usar arquivo de teste existente
input_path = '/tmp/love.webp'
puts "📊 Arquivo de entrada: #{input_path}"
puts "📊 Tamanho original: #{File.size(input_path)} bytes (#{(File.size(input_path) / 1024.0).round(1)}KB)"

# Criar service com arquivo real
file_obj = File.open(input_path, 'rb')
service = StickerImageOptimizerService.new(file: file_obj, account_id: 3)

# Executar processamento completo
puts '🔧 Iniciando processamento...'
start_time = Time.current
result = service.process
end_time = Time.current

puts "⏱️  Tempo de processamento: #{((end_time - start_time) * 1000).round(2)}ms"

if result[:success]
  puts '✅ SUCESSO!'
  puts "📊 Arquivo processado: #{result[:processed_file].class}"
  puts "📊 Tamanho final: #{result[:final_size]} bytes (#{(result[:final_size] / 1024.0).round(1)}KB)"
  puts "📊 Taxa de compressão: #{result[:compression_ratio].round(2)}%"
  puts "🎞️  Animado: #{result[:is_animated]}"
  puts "🖼️  Transparência: #{result[:has_transparency]}"
  puts "🔧 Método: #{result[:method]}"
  
  # Verificar limites
  if result[:final_size] <= 512 * 1024
    puts '✅ DENTRO DO LIMITE WHATSAPP (512KB)'
  else
    puts '⚠️  ACIMA DO LIMITE WHATSAPP'
  end
  
  margin = 512 * 1024 - result[:final_size]
  puts "📏 Margem restante: #{(margin / 1024.0).round(1)}KB"
else
  puts '❌ FALHA NO PROCESSAMENTO'
  puts "❌ Erro: #{result}"
end

file_obj.close
puts '🏁 Teste finalizado!'
