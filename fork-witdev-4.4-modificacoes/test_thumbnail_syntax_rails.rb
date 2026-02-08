#!/usr/bin/env ruby

require_relative '/app/config/environment'

puts "🔍 Testando sintaxe do thumbnail_image:"

begin
  # Criar uma imagem teste
  img = Vips::Image.black(100, 100)
  puts "   Imagem criada: 100x100"
  
  # Testar thumbnail_image com diferentes sintaxes
  begin
    thumb1 = img.thumbnail_image(50)
    puts "   ✅ thumbnail_image(50) funciona - #{thumb1.width}x#{thumb1.height}"
  rescue => e
    puts "   ❌ thumbnail_image(50): #{e.message}"
  end
  
  begin
    thumb2 = img.thumbnail_image(50, height: 50)
    puts "   ✅ thumbnail_image(50, height: 50) funciona - #{thumb2.width}x#{thumb2.height}"
  rescue => e
    puts "   ❌ thumbnail_image(50, height: 50): #{e.message}"
  end
  
  begin
    thumb3 = img.thumbnail_image(50, height: 50, crop: :centre)
    puts "   ✅ thumbnail_image(50, height: 50, crop: :centre) funciona - #{thumb3.width}x#{thumb3.height}"
  rescue => e
    puts "   ❌ thumbnail_image(50, height: 50, crop: :centre): #{e.message}"
  end
  
  # Testar resize como alternativa
  begin
    resized = img.resize(0.5)
    puts "   ✅ resize(0.5) funciona - #{resized.width}x#{resized.height}"
  rescue => e
    puts "   ❌ resize(0.5): #{e.message}"
  end
  
  puts
  puts "🔍 Documentação do thumbnail_image:"
  puts "   Método correto pode ser apenas: thumbnail_image(size)"
  puts "   Ou usar resize + crop separadamente"
  
rescue => e
  puts "❌ Erro geral: #{e.message}"
  puts "📋 Backtrace: #{e.backtrace.first(3).join(' | ')}"
end
