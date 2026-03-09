#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

puts "🚀 TESTE COMPLETO END-TO-END: FLOW REAL COM CÓDIGO ATUAL!"
puts "=" * 60

begin
  # Usar arquivo de teste atual (love.webp)
  file_path = '/tmp/love.webp'
  
  # Informações do arquivo original
  original_size = File.size(file_path)
  puts "📁 Arquivo original: #{file_path}"
  puts "📊 Tamanho original: #{original_size} bytes (#{(original_size / 1024.0).round(1)}KB)"
  
  # Verificar frames com webpinfo
  webpinfo_output = `webpinfo #{file_path} 2>&1`
  original_frames = webpinfo_output.scan(/ANMF/).length
  puts "🎬 Frames originais: #{original_frames}"
  puts "🎞️  Arquivo animado: #{original_frames > 1 ? 'SIM' : 'NÃO'}"
  
  # Criar UploadedFile real
  puts "\n🔧 ETAPA 1: Criando UploadedFile..."
  uploaded_file = ActionDispatch::Http::UploadedFile.new(
    tempfile: File.open(file_path, 'rb'),
    filename: 'love_optimized_test.webp', 
    type: 'image/webp'
  )
  
  puts "✅ UploadedFile criado com sucesso"
  
  # Testar primeiro nosso StickerImageOptimizerService diretamente
  puts "\n🔧 ETAPA 2: Testando StickerImageOptimizerService (nosso código)..."
  optimizer_start = Time.current
  
  file_obj = File.open(file_path, 'rb')
  optimizer = StickerImageOptimizerService.new(file: file_obj, account_id: 3)
  optimizer_result = optimizer.process
  
  optimizer_time = ((Time.current - optimizer_start) * 1000).round(2)
  
  if optimizer_result[:success]
    puts "✅ StickerImageOptimizerService: SUCESSO!"
    puts "   📊 Tamanho otimizado: #{optimizer_result[:final_size]} bytes (#{(optimizer_result[:final_size] / 1024.0).round(1)}KB)"
    puts "   ⏱️  Tempo otimização: #{optimizer_time}ms"
    puts "   🎞️  Animado: #{optimizer_result[:is_animated]}"
    puts "   🖼️  Transparência: #{optimizer_result[:has_transparency]}"
    puts "   🔧 Método: #{optimizer_result[:method]}"
    
    # Verificar se está dentro do limite WhatsApp
    if optimizer_result[:final_size] <= 512 * 1024
      puts "   ✅ DENTRO DO LIMITE WHATSAPP (#{optimizer_result[:final_size]} ≤ 512KB)"
    else
      puts "   ⚠️  ACIMA DO LIMITE WHATSAPP"
    end
  else
    puts "❌ StickerImageOptimizerService FALHOU"
    file_obj.close
    exit 1
  end
  
  file_obj.close
  
  puts "\n🔧 ETAPA 3: Testando StickerService (fluxo completo)..."
  start_time = Time.current
  
  result = StickerService.new(Account.find(3)).create_custom_sticker(
    'love_optimized_end_to_end',
    uploaded_file,
    ['optimized', 'test', 'end_to_end', '458kb']
  )
  
  end_time = Time.current
  total_processing_time = (end_time - start_time) * 1000
  
  puts "⏱️ Tempo TOTAL (StickerService completo): #{total_processing_time.round(2)}ms"
  
  if result[:success]
    puts "\n🎉 SUCESSO COMPLETO END-TO-END!"
    puts "✅ Sticker ID: #{result[:sticker][:id]}"
    puts "📁 URL: #{result[:sticker][:url]}"
    
    puts "\n🔧 ETAPA 4: Verificando arquivo salvo no disco..."
    
    # Buscar attachment para verificar arquivo final no ActiveStorage
    attachment = Attachment.find(result[:sticker][:id])
    blob_key = attachment.file.blob.key
    storage_path = "/app/storage/#{blob_key[0..1]}/#{blob_key[2..3]}/#{blob_key}"
    
    puts "📂 Caminho no storage: #{storage_path}"
    
    if File.exist?(storage_path)
      final_size = File.size(storage_path)
      puts "📊 Tamanho final no disco: #{final_size} bytes (#{(final_size / 1024.0).round(1)}KB)"
      
      # Calcular redução de tamanho
      size_reduction = ((original_size - final_size).to_f / original_size * 100).round(2)
      puts "📊 Redução de tamanho: #{size_reduction}%"
      
      # Verificar frames no arquivo final
      puts "\n🔧 ETAPA 5: Validando frames e animação..."
      final_webpinfo = `webpinfo #{storage_path} 2>&1`
      
      # Contar frames
      final_frames = final_webpinfo.scan(/ANMF/).length
      animation_flag = final_webpinfo.match(/Animation: (\d+)/)&.captures&.first&.to_i
      
      puts "🎬 Frames finais: #{final_frames}"
      puts "🎬 Animation flag: #{animation_flag}"
      
      # Verificar conformidade WhatsApp
      puts "\n📋 VALIDAÇÃO FINAL:"
      
      if final_size <= 512 * 1024
        puts "✅ DENTRO DO LIMITE WHATSAPP! (#{final_size} ≤ 524288 bytes)"
      else
        puts "❌ ACIMA DO LIMITE WHATSAPP (#{final_size} > 524288 bytes)"
      end
      
      if final_frames == original_frames && animation_flag == 1
        puts "✅ TODOS OS #{original_frames} FRAMES PRESERVADOS!"
        puts "✅ ANIMAÇÃO ATIVA!"
      elsif final_frames > 0 && animation_flag == 1
        puts "⚠️ Frames reduzidos: #{final_frames}/#{original_frames} (mas animação ativa)"
      else
        puts "❌ Animação perdida ou frames não preservados"
      end
      
      # Mostrar durações para verificar se foram preservadas
      durations = final_webpinfo.scan(/Duration: (\d+)/).flatten.uniq
      puts "⏰ Durações encontradas: #{durations.join(', ')}ms"
      
      puts "\n🎯 RESUMO DO TESTE END-TO-END:"
      puts "   📊 Original: #{(original_size / 1024.0).round(1)}KB → Final: #{(final_size / 1024.0).round(1)}KB"
      puts "   📈 Redução: #{size_reduction}%"
      puts "   🎬 Frames: #{original_frames} → #{final_frames}"
      puts "   ⏱️  Otimização: #{optimizer_time}ms"
      puts "   ⏱️  Total: #{total_processing_time.round(2)}ms"
      puts "   🔧 Método: #{optimizer_result[:method] if optimizer_result}"
      puts "   🎯 WhatsApp: #{final_size <= 512 * 1024 ? 'COMPATÍVEL ✅' : 'INCOMPATÍVEL ❌'}"
      
      # Copiar arquivo final para uploaders para inspeção
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      copy_path = "/app/app/uploaders/sticker_end_to_end_#{timestamp}.webp"
      FileUtils.cp(storage_path, copy_path)
      puts "\n📁 Arquivo copiado para inspeção: #{copy_path}"
      
    else
      puts "❌ Arquivo final não encontrado no storage: #{storage_path}"
      puts "🔍 Verificando se há erro no blob..."
      puts "📋 Blob info: #{attachment.file.blob.inspect}"
    end
    
  else
    puts "❌ FALHA NO STICKERSERVICE:"
    if result[:errors].is_a?(ActiveModel::Errors)
      puts "📋 Detalhes dos erros de validação:"
      result[:errors].full_messages.each { |msg| puts "   • #{msg}" }
      
      # Mostrar erros por campo
      result[:errors].details.each do |field, details|
        puts "   🔸 #{field}: #{details}"
      end
    else
      puts "#{result[:errors]}"
    end
    puts "Código: #{result[:error_code]}" if result[:error_code]
    
    # Tentar entender qual validação falhou
    puts "\n🔍 Debug adicional:"
    if result[:model] && result[:model].respond_to?(:errors)
      puts "📋 Erros do modelo:"
      result[:model].errors.full_messages.each { |msg| puts "   • #{msg}" }
    end
  end
  
rescue => e
  puts "❌ ERRO CRÍTICO NO TESTE: #{e.message}"
  puts "📋 Classe: #{e.class.name}"
  puts "📋 Backtrace:"
  e.backtrace.first(5).each { |line| puts "   #{line}" }
end

puts "\n📋 Logs recentes do processamento:"
puts `tail -15 /app/log/development.log | grep -E 'STICKER|LIBVIPS|FRAMES|SOCIALWISE'`

puts "\n🏁 TESTE END-TO-END FINALIZADO!"
