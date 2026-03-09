#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

puts '🎬 Teste completo: Otimização → Arquivo Intermediário → StickerUploader → Disco'

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
  
  # 2. Salvar arquivo otimizado temporariamente
  temp_optimized_path = "/tmp/optimized_for_uploader_#{Time.now.to_i}.webp"
  
  puts '🔧 Etapa 2: Salvando arquivo otimizado temporariamente...'
  File.open(temp_optimized_path, 'wb') do |f|
    optimized_file.rewind if optimized_file.respond_to?(:rewind)
    content = optimized_file.read
    f.write(content)
  end
  
  temp_size = File.size(temp_optimized_path)
  puts "💾 Arquivo temporário salvo: #{(temp_size / 1024.0).round(1)}KB"
  
  # 3. Criar novo File objeto para o StickerUploader
  puts '🔧 Etapa 3: Processando com StickerUploader...'
  
  # Criar um ActionDispatch::Http::UploadedFile simulando upload
  temp_file = File.open(temp_optimized_path, 'rb')
  uploaded_file = ActionDispatch::Http::UploadedFile.new(
    tempfile: temp_file,
    filename: 'optimized_sticker.webp',
    type: 'image/webp'
  )
  
  uploader = StickerUploader.new(
    file: uploaded_file,
    pack_name: 'test_pack_458kb'
  )
  
  if uploader.process_and_validate
    puts "✅ StickerUploader validação passou!"
    
    # 4. Obter arquivo processado pelo uploader
    processed_file = uploader.processed_file
    
    if processed_file
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      dest_path = "/app/app/uploaders/sticker_final_#{timestamp}.webp"
      
      # Copiar arquivo processado para destino final
      if processed_file.respond_to?(:path) && processed_file.path && File.exist?(processed_file.path)
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
      puts "   🔄 Fluxo: Input → Optimizer → TempFile → Uploader → Disco ✅"
      
    else
      puts "❌ StickerUploader não gerou arquivo processado"
    end
    
  else
    puts "❌ StickerUploader falhou na validação:"
    uploader.errors.full_messages.each { |error| puts "   • #{error}" }
  end
  
  # Cleanup
  temp_file.close
  File.delete(temp_optimized_path) if File.exist?(temp_optimized_path)
  
else
  puts "❌ Falha na otimização inicial"
end

file_obj.close
puts '🏁 Teste finalizado!'
