#!/usr/bin/env ruby
require_relative 'config/environment'
require 'vips'

puts "🔍 Debug - Verificando erro thumbnail_image"
puts "=" * 50

foto_path = 'app/uploaders/foto.jpg'

if File.exist?(foto_path)
  puts "📁 Arquivo encontrado: #{foto_path}"
  
  begin
    # Testar se a libvips consegue carregar a imagem
    puts "\n🧪 Teste 1: Carregando imagem com libvips..."
    image = Vips::Image.new_from_file(foto_path)
    puts "✅ Imagem carregada: #{image.width}x#{image.height}"
    
    # Testar thumbnail_image com diferentes argumentos
    puts "\n🧪 Teste 2: thumbnail_image com 1 argumento (512)..."
    begin
      thumb1 = image.thumbnail_image(512)
      puts "✅ thumbnail_image(512) funciona: #{thumb1.width}x#{thumb1.height}"
    rescue => e
      puts "❌ Erro com 1 argumento: #{e.message}"
      puts "🔍 Classe do erro: #{e.class}"
    end
    
    puts "\n🧪 Teste 3: thumbnail_image com 2 argumentos (512, 512)..."
    begin
      thumb2 = image.thumbnail_image(512, 512)
      puts "✅ thumbnail_image(512, 512) funciona: #{thumb2.width}x#{thumb2.height}"
    rescue => e
      puts "❌ Erro com 2 argumentos: #{e.message}"
      puts "🔍 Classe do erro: #{e.class}"
    end
    
    puts "\n🧪 Teste 4: Verificando métodos disponíveis..."
    methods = image.methods.grep(/thumbnail/)
    puts "📋 Métodos thumbnail disponíveis: #{methods}"
    
    # Verificar se há algum método thumbnail_image customizado
    puts "\n🧪 Teste 5: Verificando definição do método..."
    method_info = image.method(:thumbnail_image)
    puts "📋 Método thumbnail_image: #{method_info}"
    puts "📋 Arity (número de argumentos): #{method_info.arity}"
    
  rescue => e
    puts "💥 Erro ao carregar imagem: #{e.message}"
    puts "🔍 Backtrace:"
    puts e.backtrace.first(3).join("\n")
  end
  
else
  puts "❌ Arquivo não encontrado: #{foto_path}"
end

puts "\n" + "=" * 50
puts "🏁 Debug finalizado"
