#!/usr/bin/env ruby

require_relative '/app/config/environment'

puts "🧪 TESTE: Limite de 100KB para Imagens Estáticas"
puts "=" * 60

# Simular arquivo estático grande (PNG convertido para WebP)
class MockStaticFile
  attr_reader :size, :content_type
  
  def initialize(size_kb = 200) # Simular arquivo de 200KB
    @size = size_kb * 1024
    @content_type = 'image/webp'
    # Simular conteúdo WebP estático
    @content = "RIFF" + "WEBP" + ("A" * (@size - 8))
  end
  
  def read
    @content
  end
  
  def rewind
  end
  
  def respond_to?(method)
    [:read, :rewind, :size, :content_type].include?(method)
  end
end

begin
  puts "📊 CONFIGURAÇÃO DO TESTE:"
  puts "   Limite estático: #{StickerImageOptimizerService::MAX_STATIC_FILE_SIZE} bytes (#{StickerImageOptimizerService::MAX_STATIC_FILE_SIZE / 1024}KB)"
  puts "   Limite animado: #{StickerImageOptimizerService::MAX_ANIMATED_FILE_SIZE} bytes (#{StickerImageOptimizerService::MAX_ANIMATED_FILE_SIZE / 1024}KB)"
  puts
  
  # Teste com arquivo estático simulado
  mock_file = MockStaticFile.new(200) # 200KB
  puts "🖼️ TESTE COM IMAGEM ESTÁTICA SIMULADA:"
  puts "   Tamanho original: #{mock_file.size} bytes (#{(mock_file.size / 1024.0).round(1)}KB)"
  puts "   Expectativa: Sistema deve otimizar para ≤ 100KB"
  puts
  
  service = StickerImageOptimizerService.new(file: mock_file, account_id: 3)
  
  puts "🚀 EXECUTANDO OTIMIZAÇÃO..."
  result = service.process
  
  puts "📊 RESULTADO:"
  puts "   Success: #{result[:success]}"
  
  if result[:success]
    puts "   Final size: #{result[:final_size]} bytes (#{(result[:final_size] / 1024.0).round(1)}KB)"
    puts "   Compression: #{result[:compression_ratio]}%"
    puts "   Animated: #{result[:is_animated]}"
    
    # Verificar se respeitou o limite
    if result[:is_animated]
      limit = StickerImageOptimizerService::MAX_ANIMATED_FILE_SIZE
      puts "   Limit check: #{result[:final_size] <= limit ? '✅' : '❌'} Animated limit (#{result[:final_size]} ≤ #{limit})"
    else
      limit = StickerImageOptimizerService::MAX_STATIC_FILE_SIZE
      puts "   Limit check: #{result[:final_size] <= limit ? '✅' : '❌'} Static limit (#{result[:final_size]} ≤ #{limit})"
    end
  else
    puts "   Error: #{result[:error]}"
  end
  
rescue => e
  puts "❌ ERRO: #{e.message}"
  puts "📍 Class: #{e.class.name}"
  puts "📋 Backtrace:"
  e.backtrace.first(5).each { |line| puts "   #{line}" }
end

puts
puts "📝 COMPORTAMENTO ESPERADO:"
puts "   1. Detectar imagem como estática (não animada)"
puts "   2. Aplicar iteração de qualidades: Q75, Q65, Q55, etc."
puts "   3. Parar quando atingir ≤ 100KB"
puts "   4. Logs específicos para limite estático"
