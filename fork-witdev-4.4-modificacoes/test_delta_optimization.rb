#!/usr/bin/env ruby

# Adicionar diretório lib ao load path para carregar dependências
$LOAD_PATH.unshift(File.expand_path('../../../lib', __FILE__))

# Configurar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require '/app/config/environment'

puts "🚀 TESTE DELTA WEBP: Otimização de Diferenciação de Frames!"
puts "=" * 60

begin
  file_path = '/tmp/love_134frames.webp'
  
  # Informações do arquivo original
  original_size = File.size(file_path)
  puts "📁 Arquivo original: #{original_size} bytes (~#{(original_size / 1024.0).round(1)}KB)"
  
  # Verificar frames com webpinfo
  webpinfo_output = `webpinfo #{file_path} 2>&1`
  original_frames = webpinfo_output.scan(/ANMF/).length
  puts "🎬 Frames originais: #{original_frames}"
  
  # Criar UploadedFile
  uploaded_file = ActionDispatch::Http::UploadedFile.new(
    tempfile: File.open(file_path, 'rb'),
    filename: 'love_delta_test.webp', 
    type: 'image/webp'
  )
  
  puts "\n🔧 Iniciando processamento com OTIMIZAÇÃO DELTA..."
  start_time = Time.current
  
  result = StickerService.new(Account.find(3)).create_custom_sticker(
    'love_delta_134',
    uploaded_file,
    ['delta', 'test', 'optimization']
  )
  
  end_time = Time.current
  processing_time = (end_time - start_time) * 1000
  
  puts "⏱️ Tempo total de processamento: #{processing_time.round(2)}ms"
  
  if result[:success]
    puts "\n🎉 SUCESSO COM DELTA OPTIMIZATION!"
    puts "✅ Sticker ID: #{result[:sticker][:id]}"
    
    # Buscar attachment para verificar arquivo final
    attachment = Attachment.find(result[:sticker][:id])
    blob_key = attachment.file.blob.key
    storage_path = "/app/storage/#{blob_key[0..1]}/#{blob_key[2..3]}/#{blob_key}"
    
    if File.exist?(storage_path)
      final_size = File.size(storage_path)
      puts "📊 Tamanho final: #{final_size} bytes (~#{(final_size / 1024.0).round(1)}KB)"
      puts "📊 Compressão: #{((original_size - final_size).to_f / original_size * 100).round(2)}%"
      
      # Verificar se ficou dentro do limite do WhatsApp
      whatsapp_limit = 500 * 1024  # 500KB
      if final_size <= whatsapp_limit
        puts "🎊 VITÓRIA! ARQUIVO DENTRO DO LIMITE DO WHATSAPP!"
        puts "✅ #{final_size} bytes ≤ #{whatsapp_limit} bytes (500KB)"
      else
        puts "⚠️ Ainda acima do limite: #{final_size} vs #{whatsapp_limit} bytes"
        puts "📈 Redução necessária: #{((final_size - whatsapp_limit).to_f / 1024).round(1)}KB"
      end
      
      # Verificar frames no arquivo final
      final_webpinfo = `webpinfo #{storage_path} 2>&1`
      
      # Contar frames
      final_frames = final_webpinfo.scan(/ANMF/).length
      animation_flag = final_webpinfo.match(/Animation: (\d+)/)&.captures&.first&.to_i
      
      puts "🎬 Frames finais: #{final_frames}"
      puts "🎬 Animation flag: #{animation_flag}"
      
      if final_frames == original_frames && animation_flag == 1
        puts "\n🏆 DELTA OPTIMIZATION PERFEITA!"
        puts "✅ TODOS OS #{original_frames} FRAMES PRESERVADOS!"
        puts "✅ ANIMAÇÃO ATIVA!"
        puts "✅ TAMANHO OTIMIZADO COM DIFERENCIAÇÃO!"
      elsif final_frames > 0
        puts "\n⚠️ Resultado parcial:"
        puts "📊 Frames preservados: #{final_frames}/#{original_frames}"
      else
        puts "\n❌ Animação perdida"
      end
      
      # Mostrar durações para verificar se foram preservadas
      durations = final_webpinfo.scan(/Duration: (\d+)/).flatten.uniq
      puts "⏰ Durações encontradas: #{durations.join(', ')}ms"
      
      # Mostrar estratégia usada
      puts "\n📋 Últimos logs da otimização delta:"
      puts `tail -5 /app/log/development.log | grep -E 'STICKER|delta|strategy|diff'`
      
    else
      puts "❌ Arquivo final não encontrado: #{storage_path}"
    end
    
  else
    puts "❌ FALHA:"
    puts "#{result[:errors]}"
    puts "Código: #{result[:error_code]}"
  end
  
rescue => e
  puts "❌ ERRO CRÍTICO: #{e.message}"
  puts e.backtrace.first(5)
end
