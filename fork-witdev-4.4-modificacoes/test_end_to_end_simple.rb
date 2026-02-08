#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

puts '🚀 TESTE END-TO-END SIMPLIFICADO (SEM STICKERSERVICE)'
puts '=' * 60

begin
  # Usar arquivo de teste teste-stiker.webp
  file_path = '/app/app/uploaders/teste-stiker.webp'
  
  puts "📁 Arquivo: #{file_path}"
  puts "📊 Tamanho original: #{File.size(file_path)} bytes (#{(File.size(file_path) / 1024.0).round(1)}KB)"
  
  # ETAPA 1: Processar com StickerImageOptimizerService
  puts "\n🔧 ETAPA 1: Otimizando com StickerImageOptimizerService..."
  
  # Verificar animação original
  original_image = Vips::Image.new_from_file(file_path, n: -1)
  original_frames = original_image.get("n-pages")
  original_delays = original_image.get("delay")
  original_total_time = original_delays.sum
  
  puts "   🎞️  Frames originais: #{original_frames}"
  puts "   ⏰ Delays originais: #{original_delays.inspect}"
  puts "   🕐 Tempo total original: #{original_total_time}ms"
  
  file_obj = File.open(file_path, 'rb')
  optimizer = StickerImageOptimizerService.new(file: file_obj, account_id: 3)
  
  start_time = Time.current
  result = optimizer.process
  optimizer_time = ((Time.current - start_time) * 1000).round(2)
  
  if result[:success]
    puts "✅ Otimização: SUCESSO!"
    puts "   📊 Tamanho: #{result[:final_size]} bytes (#{(result[:final_size] / 1024.0).round(1)}KB)"
    puts "   ⏱️  Tempo: #{optimizer_time}ms"
    puts "   🎞️  Animado: #{result[:is_animated]}"
    puts "   🔧 Método: #{result[:method]}"
    
    # Verificar compensação de tempo se for animado
    if result[:is_animated]
      processed_file = result[:processed_file]
      processed_image = Vips::Image.new_from_file(processed_file.path, n: -1)
      processed_frames = processed_image.get("n-pages")
      processed_delays = processed_image.get("delay")
      processed_total_time = processed_delays.sum
      
      puts "\n🎞️ ANÁLISE DE COMPENSAÇÃO DE TEMPO:"
      puts "   📊 Frames: #{original_frames} → #{processed_frames}"
      puts "   ⏰ Delays: #{original_delays.inspect} → #{processed_delays.inspect}"
      puts "   🕐 Tempo total: #{original_total_time}ms → #{processed_total_time}ms"
      puts "   📈 Preservação: #{((processed_total_time.to_f / original_total_time) * 100).round(1)}%"
      
      if (processed_total_time - original_total_time).abs <= 50 # Tolerância de 50ms
        puts "   ✅ Tempo total preservado com sucesso!"
      else
        puts "   ⚠️  Tempo total não preservado adequadamente"
      end
    end
    
    # ETAPA 2: Salvar arquivo otimizado no disco via ActiveStorage
    puts "\n🔧 ETAPA 2: Analisando arquivo processado..."
    
    processed_file = result[:processed_file]
    puts "   🔍 Tipo: #{processed_file.class}"
    puts "   🔍 Path: #{processed_file.path rescue 'N/A'}"
    
    puts "\n🔧 ETAPA 2.1: Salvando arquivo temporário..."
    
    # Salvar em local permanente primeiro usando o path do tempfile
    temp_path = "/tmp/optimized_permanent_#{Time.now.to_i}.webp"
    
    # Como o arquivo ainda está aberto, podemos usar seu path
    if processed_file.respond_to?(:path) && processed_file.path && File.exist?(processed_file.path)
      FileUtils.cp(processed_file.path, temp_path)
      puts "✅ Arquivo copiado via path: #{temp_path} (#{File.size(temp_path)} bytes)"
    else
      puts "❌ Path do arquivo processado não disponível ou arquivo não existe"
      puts "   Debug: path=#{processed_file.path.inspect}"
      raise "Não foi possível acessar arquivo processado"
    end
    
    puts "✅ Arquivo temporário salvo: #{temp_path} (#{File.size(temp_path)} bytes)"
    
    puts "\n🔧 ETAPA 3: Salvando no ActiveStorage (usando dados reais)..."
    
    # Usar dados reais extraídos da URL: http://localhost:3000/app/accounts/3/inbox/4/conversations/1987
    account = Account.find(3)
    inbox = Inbox.find(4)
    conversation = Conversation.find(1987)
    
    # Criar uma nova mensagem na conversa existente
    message = conversation.messages.create!(
      account: account,
      inbox: inbox,
      content: "Teste de anexo de sticker otimizado",
      message_type: 'outgoing',
      source_id: "sticker_test_#{Time.now.to_i}"
    )
    
    attachment = Attachment.new
    attachment.account = account
    attachment.message = message
    attachment.file_type = :image
    
    # Anexar arquivo usando o arquivo salvo
    attachment.file.attach(
      io: File.open(temp_path),
      filename: "sticker_optimized_#{Time.now.to_i}.webp",
      content_type: 'image/webp'
    )
    
    if attachment.save
      puts "✅ ActiveStorage: SUCESSO!"
      
      # ETAPA 3: Verificar arquivo salvo
      puts "\n🔧 ETAPA 3: Verificando arquivo no disco..."
      
      blob = attachment.file.blob
      storage_path = Rails.application.routes.url_helpers.rails_blob_path(blob)
      
      # Tentar encontrar arquivo físico
      storage_key = blob.key
      physical_path = "/app/storage/#{storage_key[0..1]}/#{storage_key[2..3]}/#{storage_key}"
      
      if File.exist?(physical_path)
        final_size = File.size(physical_path)
        puts "✅ Arquivo encontrado no disco!"
        puts "   📂 Path: #{physical_path}"
        puts "   📊 Tamanho: #{final_size} bytes (#{(final_size / 1024.0).round(1)}KB)"
        puts "   🎯 WhatsApp: #{final_size <= 512 * 1024 ? 'COMPATÍVEL ✅' : 'INCOMPATÍVEL ❌'}"
        
        # Copiar para uploaders
        timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
        copy_path = "/app/app/uploaders/sticker_end2end_#{timestamp}.webp"
        FileUtils.cp(physical_path, copy_path)
        
        puts "\n🎉 TESTE END-TO-END COMPLETO!"
        puts "   📁 Arquivo original: #{(File.size(file_path) / 1024.0).round(1)}KB"
        puts "   📁 Arquivo final: #{(final_size / 1024.0).round(1)}KB"
        puts "   📊 Redução: #{((File.size(file_path) - final_size).to_f / File.size(file_path) * 100).round(2)}%"
        puts "   📂 Copiado para: #{copy_path}"
        puts "   🔄 Flow: Input → Optimizer → ActiveStorage → Disco ✅"
        
      else
        puts "❌ Arquivo não encontrado: #{physical_path}"
      end
      
    else
      puts "❌ Falha ao salvar no ActiveStorage:"
      attachment.errors.full_messages.each { |msg| puts "   • #{msg}" }
    end
    
  else
    puts "❌ Falha na otimização"
  end
  
  file_obj.close
  
rescue => e
  puts "❌ ERRO: #{e.message}"
  puts "📋 Backtrace:"
  e.backtrace.first(5).each { |line| puts "   #{line}" }
end

puts "\n🏁 Teste finalizado!"
