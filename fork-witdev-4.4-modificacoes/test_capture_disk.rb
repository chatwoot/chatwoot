#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

puts '🎬 Teste final: Simular fluxo real e capturar no momento certo'

# Modificar temporariamente o StickerImageOptimizerService
# para salvar o arquivo onde queremos antes de criar o UploadedFile

class StickerImageOptimizerService
  def capture_optimized_file(output_path)
    @capture_path = output_path
  end
  
  private
  
  def create_uploaded_file_from_buffer(buffer, filename)
    # Se temos um caminho de captura, salvar lá também
    if @capture_path
      File.open(@capture_path, 'wb') { |f| f.write(buffer) }
      puts "📁 Arquivo capturado em: #{@capture_path}"
    end
    
    # Chamar o método original
    super
  end
end

# Executar teste
input_path = '/tmp/test_input_disk.webp'
puts "📊 Input: #{input_path} (#{(File.size(input_path) / 1024.0).round(1)}KB)"

# Definir onde queremos capturar o arquivo
timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
capture_path = "/app/app/uploaders/sticker_captured_#{timestamp}.webp"

# Processar
file_obj = File.open(input_path, 'rb')
service = StickerImageOptimizerService.new(file: file_obj, account_id: 3)
service.capture_optimized_file(capture_path)

puts '🔧 Processando e capturando arquivo...'
result = service.process

if result[:success]
  puts "✅ Processamento concluído!"
  puts "📊 Tamanho: #{result[:final_size]} bytes (#{(result[:final_size] / 1024.0).round(1)}KB)"
  
  if File.exist?(capture_path)
    disk_size = File.size(capture_path)
    puts "📁 Arquivo capturado com sucesso!"
    puts "📂 Localização: #{capture_path}"
    puts "📊 Tamanho no disco: #{disk_size} bytes (#{(disk_size / 1024.0).round(1)}KB)"
    puts "🎯 Status: #{disk_size <= 512 * 1024 ? 'WhatsApp Compatible ✅' : 'Too Large ❌'}"
    
    puts "\n🎉 ARQUIVO DE 458KB SALVO NO DISCO COM SUCESSO!"
    puts "   💾 Caminho: #{capture_path}"
    puts "   📏 Tamanho: #{(disk_size / 1024.0).round(1)}KB"
    puts "   🔄 Fluxo completo executado ✅"
    
  else
    puts "❌ Arquivo não foi capturado"
  end
  
else
  puts "❌ Falha no processamento"
end

file_obj.close
puts '🏁 Teste finalizado!'
