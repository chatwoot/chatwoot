#!/usr/bin/env ruby

require_relative '/app/config/environment'

puts "🧪 TESTE: Limite de 100KB para Imagem Estática Real"
puts "=" * 60

class TestFile
  attr_reader :size, :content_type
  
  def initialize(file_path)
    @path = file_path
    @size = File.size(file_path)
    @content_type = 'image/jpeg'  # Arquivo original é JPG
  end
  
  def read
    File.binread(@path)
  end
  
  def rewind
  end
  
  def respond_to?(method)
    [:read, :rewind, :size, :content_type].include?(method)
  end
end

begin
  file_path = '/app/app/uploaders/foto.jpg'
  test_file = TestFile.new(file_path)
  
  puts "📊 ARQUIVO DE TESTE:"
  puts "   Path: #{file_path}"
  puts "   Size: #{test_file.size} bytes (~#{(test_file.size / 1024.0).round(1)}KB)"
  puts "   Type: #{test_file.content_type}"
  puts "   Status: Imagem estática (não animada)"
  puts
  
  puts "📋 LIMITES CONFIGURADOS:"
  puts "   Estático: #{StickerImageOptimizerService::MAX_STATIC_FILE_SIZE} bytes (#{StickerImageOptimizerService::MAX_STATIC_FILE_SIZE / 1024}KB)"
  puts "   Animado: #{StickerImageOptimizerService::MAX_ANIMATED_FILE_SIZE} bytes (#{StickerImageOptimizerService::MAX_ANIMATED_FILE_SIZE / 1024}KB)"
  puts
  
  puts "🎯 EXPECTATIVA:"
  puts "   - Sistema detecta como imagem estática"
  puts "   - Converte JPG → WebP"
  puts "   - Aplica iterações de qualidade até ≤ 100KB"
  puts "   - Logs específicos para limite estático"
  puts
  
  puts "🚀 EXECUTANDO OTIMIZAÇÃO..."
  puts "=" * 40
  
  service = StickerImageOptimizerService.new(file: test_file, account_id: 3)
  
  start_time = Time.current
  result = service.process
  processing_time = (Time.current - start_time) * 1000
  
  puts
  puts "📊 RESULTADOS:"
  puts "   Success: #{result[:success]}"
  puts "   Processing time: #{processing_time.round(2)}ms"
  
  if result[:success]
    puts "   Original size: #{result[:original_size]} bytes (~#{(result[:original_size] / 1024.0).round(1)}KB)"
    puts "   Final size: #{result[:final_size]} bytes (~#{(result[:final_size] / 1024.0).round(1)}KB)"
    puts "   Compression: #{result[:compression_ratio]}%"
    puts "   Animated: #{result[:is_animated]}"
    puts "   Transparency: #{result[:has_transparency]}"
    puts "   Method: #{result[:method]}"
    
    # Verificar se respeitou o limite correto
    if result[:is_animated]
      limit = StickerImageOptimizerService::MAX_ANIMATED_FILE_SIZE
      status = result[:final_size] <= limit ? '✅' : '❌'
      puts "   Limit check: #{status} Animated limit (#{result[:final_size]} ≤ #{limit})"
    else
      limit = StickerImageOptimizerService::MAX_STATIC_FILE_SIZE
      status = result[:final_size] <= limit ? '✅' : '❌'
      puts "   Limit check: #{status} Static limit (#{result[:final_size]} ≤ #{limit})"
    end
    
    puts
    puts "🎉 ANÁLISE DO RESULTADO:"
    if !result[:is_animated] && result[:final_size] <= StickerImageOptimizerService::MAX_STATIC_FILE_SIZE
      puts "   ✅ PERFEITO! Imagem estática otimizada dentro do limite de 100KB"
      puts "   ✅ Redução significativa: #{((result[:original_size] - result[:final_size]).to_f / result[:original_size] * 100).round(1)}%"
    elsif !result[:is_animated] && result[:final_size] > StickerImageOptimizerService::MAX_STATIC_FILE_SIZE
      puts "   ⚠️ ATENÇÃO! Imagem estática ainda acima do limite de 100KB"
      puts "   📋 Pode causar problemas no WhatsApp"
    elsif result[:is_animated]
      puts "   🤔 INESPERADO! Sistema detectou como animada (deveria ser estática)"
    end
    
  else
    puts "   ❌ Error: #{result[:error]}"
  end
  
rescue => e
  puts "❌ ERRO: #{e.message}"
  puts "📍 Class: #{e.class.name}"
  puts "📋 Backtrace:"
  e.backtrace.first(5).each { |line| puts "   #{line}" }
end

puts
puts "🏁 Teste finalizado!"
