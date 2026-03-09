#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

puts '🎬 Gerando e copiando arquivo otimizado de 458KB...'

# Usar arquivo de teste existente
input_path = '/tmp/love.webp'
puts "📊 Processando: #{input_path} (#{(File.size(input_path) / 1024.0).round(1)}KB)"

# Abrir arquivo e processar
file_obj = File.open(input_path, 'rb')
service = StickerImageOptimizerService.new(file: file_obj, account_id: 3)

puts '🔧 Executando otimização...'
result = service.process

if result[:success] && result[:processed_file]
  processed_file = result[:processed_file]
  final_size = result[:final_size]
  
  puts "✅ Otimizado para: #{(final_size / 1024.0).round(1)}KB"
  
  # Criar nome de destino
  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  dest_path = "/app/app/uploaders/sticker_458kb_#{timestamp}.webp"
  
  begin
    # Tentar acessar o conteúdo antes que seja removido
    if processed_file.respond_to?(:read)
      File.open(dest_path, 'wb') do |f|
        processed_file.rewind if processed_file.respond_to?(:rewind)
        content = processed_file.read
        f.write(content)
      end
      
      saved_size = File.size(dest_path)
      puts "📁 Arquivo salvo: #{dest_path}"
      puts "📊 Tamanho verificado: #{(saved_size / 1024.0).round(1)}KB"
      puts "🎯 Status: #{saved_size <= 512 * 1024 ? 'WhatsApp Compatible ✅' : 'Too Large ❌'}"
      
    else
      puts "❌ Não foi possível ler o conteúdo do arquivo processado"
    end
    
  rescue => e
    puts "❌ Erro ao copiar: #{e.message}"
  end
  
else
  puts "❌ Falha no processamento"
end

file_obj.close
puts '🏁 Finalizado!'
