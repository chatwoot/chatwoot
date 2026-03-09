#!/usr/bin/env ruby

# Carregar o ambiente Rails
require_relative 'config/environment'

class TestStickerImageOptimizer
  def self.call(input_path, output_path, max_frames: 100)
    Rails.logger.info "[TEST-STICKER-OPTIMIZER] Starting optimization for: #{input_path}"

    image = MiniMagick::Image.open(input_path)
    
    # Verificar se é animado
    frame_count = image.frame_count
    is_animated = frame_count > 1
    
    if is_animated
      Rails.logger.info "[TEST-STICKER-OPTIMIZER] Animated sticker detected with #{frame_count} frames"
      
      # Obter delays originais
      original_delays = image[:delay]
      original_delays = Array(original_delays).map(&:to_i)
      
      Rails.logger.info "[TEST-STICKER-OPTIMIZER] Original delays: #{original_delays}"
      
      if frame_count > max_frames
        # NOVO: Calcular tempo total original
        total_time_ms = original_delays.sum
        Rails.logger.info "[TEST-STICKER-OPTIMIZER] Original total time: #{total_time_ms}ms"
        
        # Reduzir frames mantendo proporção uniforme
        frames_to_keep = select_frames_for_reduction(frame_count, max_frames)
        Rails.logger.info "[TEST-STICKER-OPTIMIZER] Keeping frames: #{frames_to_keep.inspect}"
        
        # NOVO: Calcular compensação de delay
        frame_reduction_ratio = frame_count.to_f / max_frames
        compensated_delays = original_delays.map { |delay| (delay * frame_reduction_ratio).round }
        
        Rails.logger.info "[TEST-STICKER-OPTIMIZER] Applying frame reduction ratio: #{frame_reduction_ratio}"
        Rails.logger.info "[TEST-STICKER-OPTIMIZER] Compensated delays: #{compensated_delays}"
        
        # Verificar se tempo total foi preservado
        new_total_time = compensated_delays.sum
        Rails.logger.info "[TEST-STICKER-OPTIMIZER] New total time: #{new_total_time}ms (diff: #{new_total_time - total_time_ms}ms)"
      end
    end
    
    # Por simplicidade, apenas copiar o arquivo
    FileUtils.cp(input_path, output_path)
    
    Rails.logger.info "[TEST-STICKER-OPTIMIZER] Optimization completed: #{output_path}"
    true
  end
  
  private
  
  def self.select_frames_for_reduction(total_frames, max_frames)
    return (0...total_frames).to_a if total_frames <= max_frames
    
    step = total_frames.to_f / max_frames
    selected_frames = []
    
    max_frames.times do |i|
      frame_index = (i * step).round
      frame_index = [frame_index, total_frames - 1].min
      selected_frames << frame_index
    end
    
    selected_frames.uniq
  end
end

# Teste usando o arquivo love.webp existente
input_file = Rails.root.join("app/uploaders/love.webp").to_s
output_file = Rails.root.join("app/uploaders/love_time_compensated.webp").to_s

puts "="*80
puts "TESTE DE COMPENSAÇÃO DE TEMPO - LOVE.WEBP"
puts "="*80

# Verificar se o arquivo existe
unless File.exist?(input_file)
  puts "ERRO: Arquivo #{input_file} não encontrado!"
  exit 1
end

# Primeiro, vamos verificar as propriedades do arquivo original
puts "\n1. ANÁLISE DO ARQUIVO ORIGINAL:"
puts "-" * 40

begin
  original_image = MiniMagick::Image.open(input_file)
  original_frame_count = original_image.frame_count
  original_delays = original_image[:delay]
  original_delays = Array(original_delays).map(&:to_i)
  original_total_time = original_delays.sum
  
  puts "Frame count: #{original_frame_count}"
  puts "Original delays: #{original_delays}"
  puts "Total time: #{original_total_time}ms (#{original_total_time/1000.0}s)"
  
  if original_frame_count <= 10
    puts "AVISO: Arquivo tem #{original_frame_count} frames, não será reduzido (limite: 10)"
    puts "Testando com limite menor para forçar redução..."
    max_frames = 5
  else
    max_frames = 10
  end
  
rescue => e
  puts "ERRO ao analisar arquivo: #{e.message}"
  exit 1
end

puts "\n2. TESTE DE OTIMIZAÇÃO (max_frames: #{max_frames}):"
puts "-" * 40

# Executar o serviço
result = TestStickerImageOptimizer.call(input_file, output_file, max_frames: max_frames)

if result
  puts "\n3. VERIFICAÇÃO DO RESULTADO:"
  puts "-" * 40
  
  if File.exist?(output_file)
    puts "✅ Arquivo otimizado criado com sucesso: #{output_file}"
    
    # Verificar tamanho do arquivo
    original_size = File.size(input_file)
    optimized_size = File.size(output_file)
    
    puts "📊 Tamanho original: #{original_size} bytes"
    puts "📊 Tamanho otimizado: #{optimized_size} bytes"
    puts "📊 Redução: #{((1 - optimized_size.to_f/original_size) * 100).round(2)}%"
  else
    puts "❌ Arquivo otimizado não foi criado"
  end
else
  puts "❌ Erro durante a otimização"
end

puts "\n" + "="*80
puts "TESTE CONCLUÍDO"
puts "="*80
