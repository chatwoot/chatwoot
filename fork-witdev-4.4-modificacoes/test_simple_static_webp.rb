#!/usr/bin/env ruby

require_relative '/app/config/environment'

puts "🧪 TESTE SIMPLIFICADO: Limite de 100KB para Imagem Estática"
puts "=" * 60

# Primeiro vou testar se conseguimos processar um WebP estático simples
begin
  puts "🔍 Criando uma imagem WebP estática de teste..."
  
  # Criar uma imagem grande em memória e salvar como WebP
  large_image = Vips::Image.black(1024, 1024)  # 1024x1024 = grande
  test_path = '/tmp/test_static.webp'
  large_image.webpsave(test_path, Q: 90)  # Alta qualidade = tamanho grande
  
  original_size = File.size(test_path)
  puts "✅ Imagem de teste criada: #{original_size} bytes (~#{(original_size/1024.0).round(1)}KB)"
  
  # Agora testar se o StickerImageOptimizerService consegue processar
  class TestFile
    attr_reader :size, :content_type
    def initialize(file_path)
      @path = file_path
      @size = File.size(file_path)
      @content_type = 'image/webp'
    end
    def read; File.binread(@path); end
    def rewind; end
    def respond_to?(method); [:read, :rewind, :size, :content_type].include?(method); end
  end
  
  test_file = TestFile.new(test_path)
  service = StickerImageOptimizerService.new(file: test_file, account_id: 3)
  
  puts "🚀 Executando otimização na imagem WebP estática..."
  result = service.process
  
  puts "📊 RESULTADO:"
  puts "   Success: #{result[:success]}"
  if result[:success]
    puts "   Original: #{result[:original_size]} bytes"
    puts "   Final: #{result[:final_size]} bytes"
    puts "   Animated: #{result[:is_animated]}"
    limit = StickerImageOptimizerService::MAX_STATIC_FILE_SIZE
    puts "   Within limit: #{result[:final_size] <= limit ? '✅' : '❌'} (#{result[:final_size]} ≤ #{limit})"
  else
    puts "   Error: #{result[:error]}"
  end
  
  # Limpeza
  File.delete(test_path) if File.exist?(test_path)
  
rescue => e
  puts "❌ ERRO: #{e.message}"
  puts "📍 Class: #{e.class.name}"
  puts "📋 Backtrace:"
  e.backtrace.first(5).each { |line| puts "   #{line}" }
  File.delete(test_path) if defined?(test_path) && File.exist?(test_path)
end
