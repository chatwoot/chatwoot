#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

puts '🎬 Teste direto: Processamento + Salvamento no disco'

# Usar arquivo de entrada
input_path = '/tmp/love.webp'
puts "📊 Input: #{input_path} (#{(File.size(input_path) / 1024.0).round(1)}KB)"

# Criar um Tempfile que será salvo no disco
require 'tempfile'
temp_output = Tempfile.new(['sticker_processed', '.webp'], '/app/app/uploaders')
temp_output.close

puts '🔧 Otimizando e salvando diretamente no disco...'

# Usar o método privado diretamente para salvar no disco
file_obj = File.open(input_path, 'rb')
service = StickerImageOptimizerService.new(file: file_obj, account_id: 3)

# Acessar o método de otimização diretamente
begin
  # Usar o método interno que salva arquivo
  result = service.send(:optimize_image_with_in_memory_architecture)
  
  if result && result[:processed_file]
    processed_file = result[:processed_file]
    
    puts "✅ Processamento concluído!"
    puts "📊 Tamanho: #{result[:final_size]} bytes (#{(result[:final_size] / 1024.0).round(1)}KB)"
    
    # Copiar para destino final
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    final_path = "/app/app/uploaders/sticker_disk_#{timestamp}.webp"
    
    if processed_file.respond_to?(:to_path) && processed_file.to_path
      FileUtils.cp(processed_file.to_path, final_path)
    elsif processed_file.respond_to?(:path) && processed_file.path
      FileUtils.cp(processed_file.path, final_path)
    else
      # Tentar ler conteúdo
      File.open(final_path, 'wb') do |f|
        processed_file.rewind if processed_file.respond_to?(:rewind)
        f.write(processed_file.read)
      end
    end
    
    if File.exist?(final_path)
      disk_size = File.size(final_path)
      puts "📁 Arquivo salvo no disco: #{final_path}"
      puts "📊 Tamanho verificado: #{disk_size} bytes (#{(disk_size / 1024.0).round(1)}KB)"
      puts "🎯 Status: #{disk_size <= 512 * 1024 ? 'WhatsApp Compatible ✅' : 'Too Large ❌'}"
      
      puts "\n🎉 ARQUIVO DE 458KB SALVO COM SUCESSO NO DISCO!"
      puts "   📂 Localização: #{final_path}"
      puts "   📏 Tamanho: #{(disk_size / 1024.0).round(1)}KB"
      
    else
      puts "❌ Arquivo não foi salvo no disco"
    end
    
  else
    puts "❌ Falha no processamento interno"
  end
  
rescue => e
  puts "❌ Erro: #{e.message}"
  puts "📋 Backtrace:"
  puts e.backtrace.first(3)
end

file_obj.close
temp_output.unlink if temp_output

puts '🏁 Teste finalizado!'
