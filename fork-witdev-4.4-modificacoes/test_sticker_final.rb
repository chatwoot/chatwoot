#!/usr/bin/env ruby

puts "🧪 Testando correção final do ActiveStorage..."

# Criar sticker com nossa correção
begin
  # Abrir arquivo e verificar
  file_path = '/tmp/test_sticker_8frames.webp'
  puts "📁 Verificando arquivo: #{file_path}"
  puts "📊 Arquivo existe: #{File.exist?(file_path)}"
  puts "📊 Tamanho: #{File.size(file_path)} bytes"
  
  file_obj = ActionDispatch::Http::UploadedFile.new(
    tempfile: File.open(file_path, 'rb'),
    filename: '200.webp',
    type: 'image/webp'
  )
  puts "📊 File object criado: #{file_obj.class}"
  puts "📊 Responde a read?: #{file_obj.respond_to?(:read)}"
  puts "📊 Responde a path?: #{file_obj.respond_to?(:path)}"
  
  result = StickerService.new(Account.find(3)).create_custom_sticker(
    'testfinal', 
    file_obj,
    ['correcao']
  )
  
  puts "📊 Resultado completo: #{result}"
  
  if result[:success]
    puts "✅ Sticker criado com ID: #{result[:sticker][:id]}"
    puts "📁 URL: #{result[:sticker][:url]}"
    
    # Buscar o attachment para pegar o blob key
    attachment = Attachment.find(result[:sticker][:id])
    puts "📁 Blob Key: #{attachment.file.blob.key}"
  else
    puts "❌ Falha na criação: #{result[:errors]}"
    puts "❌ Código do erro: #{result[:error_code]}"
    puts "❌ Mensagem: #{result[:user_message]}"
    
    # Vamos testar o uploader diretamente para ver os erros específicos
    puts "\n🔍 Testando uploader diretamente..."
    uploader = StickerUploader.new(
      file: file_obj,
      pack_name: 'testfinal',
      tags: ['correcao']
    )
    
    success = uploader.process_and_validate
    puts "📊 Uploader success: #{success}"
    puts "📊 Uploader errors: #{uploader.errors.full_messages}"
  end
  
  # Verificar arquivo final apenas se sucesso
  if result[:success]
    # O ActiveStorage usa subdiretórios baseados no key
    blob_key = attachment.file.blob.key
    # ActiveStorage usa formato: storage/XX/XX/key
    storage_path = "/app/storage/#{blob_key[0..1]}/#{blob_key[2..3]}/#{blob_key}"
    if File.exist?(storage_path)
      file_size = File.size(storage_path)
      puts "📊 Tamanho do arquivo final: #{file_size} bytes"
      
      # Usar webpinfo para verificar frames
      webpinfo_output = `webpinfo #{storage_path} 2>&1`
      puts "🔍 Saída do webpinfo:"
      puts webpinfo_output
      
      # Extrair número de frames
      frames_match = webpinfo_output.match(/Number of frames: (\d+)/)
      if frames_match
        frames = frames_match[1].to_i
        puts "🎬 Frames detectados: #{frames}"
        
        if frames >= 8
          puts "🎉 SUCESSO! Animação preservada!"
        else
          puts "❌ PROBLEMA: Apenas #{frames} frames encontrados"
        end
      else
        puts "⚠️ Não foi possível detectar frames no webpinfo"
      end
    else
      puts "❌ Arquivo não encontrado: #{storage_path}"
    end
  end
  
rescue => e
  puts "❌ Erro: #{e.message}"
  puts e.backtrace.first(5)
end
