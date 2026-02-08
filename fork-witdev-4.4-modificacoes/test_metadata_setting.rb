#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🔍 Testando definição de metadados..."

begin
  # Criar uma imagem simples de teste
  test_image = Vips::Image.black(100, 100)
  test_output = "/tmp/test_metadata.webp"
  
  puts "📝 Testando definição de delay..."
  
  # Tentar diferentes métodos para definir delay
  puts "Método 1: set..."
  test_image.set('delay', [100, 200])
  puts "✅ set funcionou"
  
  puts "Método 2: webpsave..."
  test_image.webpsave(test_output, Q: 75, page_height: 100)
  puts "✅ webpsave funcionou"
  
  # Verificar se o delay foi salvo
  puts "Verificando metadados..."
  saved_image = Vips::Image.new_from_file(test_output)
  begin
    delay = saved_image.get('delay')
    puts "✅ Delay recuperado: #{delay.inspect}"
  rescue
    puts "⚠️ Não foi possível recuperar delay"
  end
  
rescue => e
  puts "❌ Erro: #{e.class.name}: #{e.message}"
  puts "📋 Backtrace:"
  e.backtrace.first(5).each { |line| puts "  #{line}" }
end

puts "🏁 Teste finalizado!"
