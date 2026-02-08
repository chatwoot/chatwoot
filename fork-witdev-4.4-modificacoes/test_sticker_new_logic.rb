#!/usr/bin/env ruby

require_relative '/app/config/environment'

puts "🧪 TESTE COMPLETO: Nova Lógica com Sticker Real"
puts "=" * 60

# Classe para simular arquivo uploaded
class TestFile
  attr_reader :size, :content_type, :path
  
  def initialize(file_path)
    @path = file_path
    @size = File.size(file_path)
    @content_type = 'image/webp'
    @content = nil
  end
  
  def read
    @content ||= File.binread(@path)
  end
  
  def rewind
    @content = nil
  end
  
  def respond_to?(method)
    [:read, :rewind, :size, :content_type].include?(method)
  end
end

# Carregar o sticker de teste
test_file_path = 'app/uploaders/teste-stiker.webp'
test_file = TestFile.new(test_file_path)

puts "📊 ARQUIVO DE TESTE:"
puts "   Path: #{test_file_path}"
puts "   Size: #{test_file.size} bytes (~#{(test_file.size/1024.0).round(1)}KB)"
puts "   Type: #{test_file.content_type}"

# Analisar frames originais
frames_output = `webpinfo #{test_file_path}`
original_frames = frames_output.scan(/Chunk ANMF at offset/).length
puts "   Frames: #{original_frames}"
puts "   Status: #{test_file.size < 500*1024 ? 'Já dentro do limite' : 'Precisa otimização'}"
puts

begin
  puts "🚀 INICIANDO TESTE COM NOVA LÓGICA..."
  puts "=" * 40
  
  # Criar serviço
  service = StickerImageOptimizerService.new(file: test_file, account_id: 1)
  
  # Executar processamento
  start_time = Time.current
  result = service.process
  processing_time = (Time.current - start_time) * 1000
  
  puts "📊 RESULTADOS:"
  puts "   Success: #{result[:success]}"
  puts "   Processing time: #{processing_time.round(2)}ms"
  
  if result[:success]
    puts "   Original size: #{result[:original_size]} bytes"
    puts "   Final size: #{result[:final_size]} bytes"
    puts "   Compression: #{result[:compression_ratio]}%"
    puts "   Animated: #{result[:is_animated]}"
    puts "   Transparency: #{result[:has_transparency]}"
    puts "   Method: #{result[:method]}"
    
    # Analisar arquivo resultante se disponível
    if result[:processed_file] && result[:processed_file].respond_to?(:path)
      output_path = result[:processed_file].path
      if File.exist?(output_path)
        output_frames_info = `webpinfo #{output_path}`
        output_frames = output_frames_info.scan(/Chunk ANMF at offset/).length
        puts "   Output frames: #{output_frames} (original: #{original_frames})"
        puts "   Frame preservation: #{((output_frames.to_f / original_frames) * 100).round(1)}%"
      end
    end
    
    puts
    puts "🎯 ANÁLISE DA NOVA LÓGICA:"
    if result[:final_size] <= 500*1024
      puts "   ✅ Sucesso no objetivo (≤ 500KB)"
      puts "   ✅ Lógica otimizada funcionou!"
      if result[:compression_ratio] < 10
        puts "   ✅ Compressão mínima (#{result[:compression_ratio]}%) - preservou qualidade!"
      end
    else
      puts "   ⚠️ Ainda acima do limite"
    end
    
  else
    puts "   ❌ Error: #{result[:error]}"
  end
  
rescue => e
  puts "❌ ERRO NO TESTE:"
  puts "   Message: #{e.message}"
  puts "   Class: #{e.class.name}"
  puts "   Backtrace:"
  e.backtrace.first(5).each { |line| puts "     #{line}" }
end

puts
puts "📝 EXPECTATIVAS COM A NOVA LÓGICA:"
puts "   1. Sucesso na Iteração 1 (já está < 500KB)"
puts "   2. Mínima compressão aplicada"
puts "   3. Máxima preservação de frames"
puts "   4. Processamento rápido"
