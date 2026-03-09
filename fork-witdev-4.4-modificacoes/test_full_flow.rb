#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

puts '🎬 Teste completo: Otimização → StickerUploader → Disco'

# 1. Processar com StickerImageOptimizerService
input_path = '/tmp/love.webp'
puts "📊 Input: #{input_path} (#{(File.size(input_path) / 1024.0).round(1)}KB)"

file_obj = File.open(input_path, 'rb')
optimizer = StickerImageOptimizerService.new(file: file_obj, account_id: 3)

puts '🔧 Etapa 1: Otimizando com StickerImageOptimizerService...'
result = optimizer.process

if result[:success]
  optimized_file = result[:processed_file]
  puts "✅ Otimização concluída: #{(result[:final_size] / 1024.0).round(1)}KB"
  
  # 2. Processar com StickerUploader
  puts '🔧 Etapa 2: Processando com StickerUploader...'
  
  uploader = StickerUploader.new(
    file: optimized_file,
    pack_name: 'test_pack_458kb'
  )
  
  if uploader.process_and_validate
    puts "✅ StickerUploader validação passou!"
    
    # 3. Simular salvamento no disco (como o sistema real faria)
    processed_file = uploader.processed_file
    
    if processed_file
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      dest_path = "/app/app/uploaders/sticker_final_#{timestamp}.webp"
      
      # Copiar arquivo processado para destino final
      if processed_file.respond_to?(:path) && processed_file.path
        FileUtils.cp(processed_file.path, dest_path)
      elsif processed_file.respond_to?(:tempfile) && processed_file.tempfile
        FileUtils.cp(processed_file.tempfile.path, dest_path)
      else
        # Fallback: escrever conteúdo diretamente
        File.open(dest_path, 'wb') do |f|
          processed_file.rewind if processed_file.respond_to?(:rewind)
          f.write(processed_file.read)
        end
      end
      
      final_size = File.size(dest_path)
      puts "📁 Arquivo final salvo: #{dest_path}"
      puts "📊 Tamanho final no disco: #{final_size} bytes (#{(final_size / 1024.0).round(1)}KB)"
      puts "🎯 Status WhatsApp: #{final_size <= 512 * 1024 ? 'Compatible ✅' : 'Too Large ❌'}"
      
      puts "\n🎉 TESTE COMPLETO COM SUCESSO!"
      puts "   📂 Localização final: #{dest_path}"
      puts "   📏 Tamanho: #{(final_size / 1024.0).round(1)}KB"
      puts "   🔄 Fluxo: Input → Optimizer → Uploader → Disco ✅"
      
    else
      puts "❌ StickerUploader não gerou arquivo processado"
    end
    
  else
    puts "❌ StickerUploader falhou na validação:"
    uploader.errors.full_messages.each { |error| puts "   • #{error}" }
  end
  
else
  puts "❌ Falha na otimização inicial"
end

file_obj.close
puts '🏁 Teste finalizado!'
