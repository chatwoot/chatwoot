#!/usr/bin/env ruby

puts "🧪 Teste simples - sem StickerImageOptimizerService..."

# Vamos testar apenas o StickerUploader sem nossa otimização
begin
  file_path = '/tmp/test_sticker_8frames.webp'
  puts "📁 Arquivo: #{file_path}"
  puts "📊 Existe: #{File.exist?(file_path)}"
  
  file_obj = File.open(file_path, 'rb')
  
  # Simular um upload file com content_type
  uploaded_file = ActionDispatch::Http::UploadedFile.new(
    tempfile: file_obj,
    filename: '200.webp',
    type: 'image/webp'
  )
  
  puts "📊 Content type: #{uploaded_file.content_type}"
  
  # Testando só o uploader
  uploader = StickerUploader.new(
    file: uploaded_file,
    pack_name: 'test_simple',
    tags: ['test']
  )
  
  puts "🔧 Processando uploader..."
  success = uploader.process_and_validate
  
  puts "📊 Success: #{success}"
  puts "📊 Errors: #{uploader.errors.full_messages}"
  
  if success
    puts "✅ Uploader funcionou!"
    puts "📁 Processed file size: #{uploader.processed_file.size} bytes"
    puts "📁 Processed filename: #{uploader.processed_filename}"
    
    # Salvar arquivo para analisar
    output_path = "/tmp/#{uploader.processed_filename}"
    File.open(output_path, 'wb') do |f|
      uploader.processed_file.rewind
      f.write(uploader.processed_file.read)
    end
    
    puts "💾 Arquivo salvo em: #{output_path}"
    
    # Verificar frames
    webpinfo_output = `webpinfo #{output_path} 2>&1`
    puts "🔍 WebP Info:"
    puts webpinfo_output.lines.select { |line| line.match(/Number of frames|Animation|ANMF/) }.join
  else
    puts "❌ Uploader falhou"
  end
  
rescue => e
  puts "❌ Erro: #{e.message}"
  puts e.backtrace.first(3)
end
