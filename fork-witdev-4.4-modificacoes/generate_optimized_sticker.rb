#!/usr/bin/env ruby

# Carregar o ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

# Teste para gerar e salvar o sticker otimizado diretamente
puts "=== GERANDO STICKER OTIMIZADO DIRETAMENTE ==="

begin
  input_path = "/tmp/love.webp"
  
  puts "📊 Arquivo original: #{input_path}"
  puts "📊 Tamanho original: #{File.size(input_path)} bytes"

  # Criar uma instância do serviço otimizado
  file_obj = File.open(input_path, 'rb')
  service = StickerImageOptimizerService.new(file: file_obj, account_id: 3)
  
  # Usar o método público de otimização
  result = service.process
  
  if result[:success] && result[:processed_file] && File.exist?(result[:processed_file])
    result_path = result[:processed_file]
    final_size = result[:final_size]
    puts "✅ Arquivo otimizado gerado: #{result_path}"
    puts "📊 Tamanho otimizado: #{final_size} bytes (#{(final_size / 1024.0).round(1)}KB)"
    
    # Copiar para pasta de uploaders com nome único
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    dest_path = "/app/app/uploaders/sticker_optimized_#{timestamp}.webp"
    FileUtils.cp(result_path, dest_path)
    
    puts "📁 Arquivo copiado para: #{dest_path}"
    puts "📊 Tamanho final: #{(final_size / 1024.0).round(1)}KB"
    
    # Verificar se está dentro do limite do WhatsApp
    if final_size <= 512 * 1024
      puts "✅ Dentro do limite WhatsApp (512KB)"
    else
      puts "⚠️  Acima do limite WhatsApp"
    end
    puts "🎉 SUCESSO!"
    puts "📄 Arquivo salvo em: #{output_path}"
    puts "📏 Tamanho final: #{final_size} bytes"
    puts "💾 Compressão: #{((File.size(input_path) - final_size).to_f / File.size(input_path) * 100).round(2)}%"
    
    whatsapp_limit = 500 * 1024
    if final_size <= whatsapp_limit
      puts "✅ DENTRO DO LIMITE WhatsApp!"
    else
      puts "🔴 AINDA ACIMA DO LIMITE"
    end
  else
    puts "❌ Arquivo não foi criado"
  end

rescue StandardError => e
  puts "❌ EXCEÇÃO: #{e.message}"
  puts "📋 Backtrace:"
  e.backtrace.first(10).each { |line| puts "  #{line}" }
end
