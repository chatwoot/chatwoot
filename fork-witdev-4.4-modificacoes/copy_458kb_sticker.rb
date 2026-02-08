#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

puts '🎬 Gerando arquivo otimizado de 458KB e copiando...'

# Usar arquivo de teste existente
input_path = '/tmp/love.webp'
puts "📊 Arquivo de entrada: #{input_path}"
puts "📊 Tamanho original: #{File.size(input_path)} bytes (#{(File.size(input_path) / 1024.0).round(1)}KB)"

# Criar service com arquivo real
file_obj = File.open(input_path, 'rb')
service = StickerImageOptimizerService.new(file: file_obj, account_id: 3)

# Executar processamento completo
puts '🔧 Processando...'
result = service.process

if result[:success]
  processed_file = result[:processed_file]
  final_size = result[:final_size]
  
  puts "✅ Processamento concluído!"
  puts "📊 Tamanho final: #{final_size} bytes (#{(final_size / 1024.0).round(1)}KB)"
  
  # Copiar para pasta de uploaders
  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  dest_path = "/app/app/uploaders/sticker_458kb_#{timestamp}.webp"
  
  if processed_file.respond_to?(:to_path) && processed_file.to_path
    puts "📂 Copiando de: #{processed_file.to_path}"
    FileUtils.cp(processed_file.to_path, dest_path)
    
    puts "📁 Arquivo copiado para: #{dest_path}"
    puts "📊 Verificando tamanho: #{File.size(dest_path)} bytes"
    
    puts "\n🎉 Arquivo de 458KB salvo com sucesso!"
    puts "   💾 Localização: #{dest_path}"
    puts "   📏 Tamanho: #{(final_size / 1024.0).round(1)}KB"
    puts "   🎯 Status: WhatsApp Compatible (#{final_size <= 512 * 1024 ? '✅' : '❌'})"
    
  else
    puts "❌ Não foi possível acessar o arquivo temporário"
  end
else
  puts "❌ Falha no processamento"
end

file_obj.close
puts '🏁 Concluído!'
