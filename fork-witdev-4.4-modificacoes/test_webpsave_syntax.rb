#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🔍 Testando sintaxe do webpsave..."

begin
  # Criar uma imagem simples de teste
  test_image = Vips::Image.black(100, 100)
  test_output = "/tmp/test_webp_args.webp"
  
  puts "📝 Testando webpsave básico..."
  test_image.webpsave(test_output)
  puts "✅ webpsave básico funcionou"
  
  puts "📝 Testando webpsave com argumentos..."
  test_image.webpsave(test_output, Q: 75, page_height: 100)
  puts "✅ webpsave com argumentos funcionou"
  
  puts "📝 Testando com delay..."
  test_image.webpsave(test_output, Q: 75, page_height: 100, delay: [100])
  puts "✅ webpsave com delay funcionou"
  
rescue => e
  puts "❌ Erro: #{e.class.name}: #{e.message}"
  puts "📋 Backtrace:"
  e.backtrace.first(5).each { |line| puts "  #{line}" }
end

puts "🏁 Teste finalizado!"
