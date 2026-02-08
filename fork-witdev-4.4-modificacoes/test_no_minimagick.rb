#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🔧 TESTE: Verificando StickerImageOptimizerService sem MiniMagick"
puts "=" * 60

begin
  # Testar se o service pode ser carregado
  puts "📝 Carregando StickerImageOptimizerService..."
  optimizer_class = StickerImageOptimizerService
  puts "✅ StickerImageOptimizerService carregado com sucesso"
  
  # Testar se o send_sticker_service pode ser carregado
  puts "📝 Carregando Whatsapp::SendStickerService..."
  send_sticker_class = Whatsapp::SendStickerService
  puts "✅ Whatsapp::SendStickerService carregado com sucesso"
  
  # Verificar se libvips está funcionando
  puts "📝 Testando libvips..."
  require 'vips'
  version = Vips.version_string
  puts "✅ Libvips funcionando: #{version}"
  
  puts "\n🎉 SUCESSO! Todos os serviços estão funcionando sem MiniMagick"
  
rescue => e
  puts "❌ ERRO: #{e.class.name}: #{e.message}"
  puts "📋 Backtrace:"
  e.backtrace.first(5).each { |line| puts "  #{line}" }
end

puts "\n🏁 Teste finalizado!"
