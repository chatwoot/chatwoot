#!/usr/bin/env ruby

# Carregar ambiente Rails completo
require '/app/config/environment'

puts "🎯 TESTE DE OTIMIZAÇÃO PARA WHATSAPP (500KB)"
puts "=" * 60

begin
  file_path = '/tmp/love_134frames.webp'
  whatsapp_limit = 500 * 1024  # 500KB em bytes
  
  # Informações do arquivo original
  original_size = File.size(file_path)
  puts "📁 Arquivo original: #{original_size} bytes (#{(original_size.to_f / 1024 / 1024).round(2)}MB)"
  puts "🎯 Limite WhatsApp: #{whatsapp_limit} bytes (#{(whatsapp_limit.to_f / 1024).round(0)}KB)"
  
  # Verificar frames com webpinfo
  webpinfo_output = `webpinfo #{file_path} 2>&1`
  original_frames = webpinfo_output.scan(/ANMF/).length
  puts "🎬 Frames originais: #{original_frames}"
  
  # Criar UploadedFile
  uploaded_file = ActionDispatch::Http::UploadedFile.new(
    tempfile: File.open(file_path, 'rb'),
    filename: 'love_optimized.webp', 
    type: 'image/webp'
  )
  
  puts "\n🔧 Iniciando processamento OTIMIZADO..."
  start_time = Time.current
  
  result = StickerService.new(Account.find(3)).create_custom_sticker(
    'love-optimized',
    uploaded_file,
    ['optimized', 'whatsapp', '500kb']
  )
  
  end_time = Time.current
  processing_time = (end_time - start_time) * 1000
  
  puts "⏱️ Tempo total: #{processing_time.round(2)}ms"
  
  if result[:success]
    puts "\n🎉 SUCESSO!"
    puts "✅ Sticker ID: #{result[:sticker][:id]}"
    
    # Buscar attachment para verificar arquivo final
    attachment = Attachment.find(result[:sticker][:id])
    blob_key = attachment.file.blob.key
    storage_path = "/app/storage/#{blob_key[0..1]}/#{blob_key[2..3]}/#{blob_key}"
    
    if File.exist?(storage_path)
      final_size = File.size(storage_path)
      compression_ratio = ((original_size - final_size).to_f / original_size * 100).round(2)
      
      puts "📊 Tamanho final: #{final_size} bytes (#{(final_size.to_f / 1024).round(2)}KB)"
      puts "📊 Compressão: #{compression_ratio}% (#{(original_size.to_f / final_size).round(2)}x menor)"
      
      # Verificar se está dentro do limite do WhatsApp
      if final_size <= whatsapp_limit
        puts "✅ DENTRO DO LIMITE WHATSAPP! (#{final_size} ≤ #{whatsapp_limit})"
      else
        over_limit = final_size - whatsapp_limit
        puts "❌ Acima do limite: +#{over_limit} bytes (+#{(over_limit.to_f / 1024).round(2)}KB)"
      end
      
      # Verificar frames no arquivo final
      final_webpinfo = `webpinfo #{storage_path} 2>&1`
      final_frames = final_webpinfo.scan(/ANMF/).length
      animation_flag = final_webpinfo.match(/Animation: (\d+)/)&.captures&.first&.to_i
      
      puts "🎬 Frames preservados: #{final_frames}/#{original_frames}"
      puts "🎬 Animation ativa: #{animation_flag == 1 ? 'SIM' : 'NÃO'}"
      
      if final_frames > 0 && animation_flag == 1 && final_size <= whatsapp_limit
        puts "\n🏆 VITÓRIA COMPLETA!"
        puts "✅ Animação preservada"
        puts "✅ Dentro do limite WhatsApp"
        puts "✅ Qualidade otimizada"
      elsif final_frames > 0 && animation_flag == 1
        puts "\n⚠️ Sucesso parcial:"
        puts "✅ Animação preservada"
        puts "❌ Precisa mais otimização para WhatsApp"
      else
        puts "\n❌ Animação perdida na otimização"
      end
      
      # Mostrar durações
      durations = final_webpinfo.scan(/Duration: (\d+)/).flatten.uniq
      puts "⏰ Durações: #{durations.join(', ')}ms"
      
      # Mostrar qualidade estimada
      estimated_quality = estimate_quality_from_size(final_size, final_frames)
      puts "📈 Qualidade estimada: #{estimated_quality}"
      
    else
      puts "❌ Arquivo final não encontrado: #{storage_path}"
    end
    
  else
    puts "❌ FALHA:"
    puts "#{result[:errors]}"
  end
  
rescue => e
  puts "❌ ERRO: #{e.message}"
  puts e.backtrace.first(5)
end

def estimate_quality_from_size(file_size, frame_count)
  kb_per_frame = (file_size.to_f / 1024) / frame_count
  case kb_per_frame
  when 0..2
    "Baixa (#{kb_per_frame.round(1)}KB/frame)"
  when 2..5
    "Média (#{kb_per_frame.round(1)}KB/frame)"
  when 5..10
    "Alta (#{kb_per_frame.round(1)}KB/frame)"
  else
    "Muito Alta (#{kb_per_frame.round(1)}KB/frame)"
  end
end

puts "\n📋 Logs do processamento:"
puts `tail -15 /app/log/development.log | grep -E 'SOCIALWISE-STICKER|Strategy|Optimization|Animation'`
