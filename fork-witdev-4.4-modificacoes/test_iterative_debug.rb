#!/usr/bin/env ruby

# Teste do loop iterativo
puts "=== TESTE DO LOOP ITERATIVO ==="
puts "Testando constante QUALITY_LEVELS:"
puts StickerImageOptimizerService::QUALITY_LEVELS.inspect

puts "\n=== TESTANDO ARQUIVO ==="
puts "Testando com arquivo: /tmp/love.webp"

begin
  file_path = "/tmp/love.webp"
  
  # Simular arquivo uploadado
  file_content = File.read(file_path, mode: 'rb')
  
  fake_file = StringIO.new(file_content)
  fake_file.define_singleton_method(:size) { file_content.bytesize }
  fake_file.define_singleton_method(:read) { file_content }
  fake_file.define_singleton_method(:rewind) { seek(0) }

  puts "📊 Tamanho original: #{fake_file.size} bytes"

  # Criar serviço e processar
  service = StickerImageOptimizerService.new(file: fake_file, account_id: 3)
  result = service.process

  if result[:success]
    puts "🎉 SUCESSO!"
    puts "📊 Tamanho final: #{result[:final_size]} bytes"
    puts "⚡ Tempo: #{result[:processing_time]}ms"
    
    whatsapp_limit = 500 * 1024
    if result[:final_size] <= whatsapp_limit
      puts "✅ DENTRO DO LIMITE WhatsApp!"
    else
      puts "🔴 AINDA ACIMA DO LIMITE (#{result[:final_size]} > #{whatsapp_limit})"
    end
  else
    puts "❌ FALHA: #{result[:error]}"
  end

rescue StandardError => e
  puts "❌ EXCEÇÃO: #{e.message}"
  puts "📋 Backtrace:"
  e.backtrace.first(10).each { |line| puts "  #{line}" }
end
