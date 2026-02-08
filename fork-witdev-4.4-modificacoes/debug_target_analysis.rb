#!/usr/bin/env ruby

puts "🔧 TESTE DETALHADO - PROCESSO DE OTIMIZAÇÃO"
puts "============================================="

# Simular o que está acontecendo exatamente
input_path = "/app/app/uploaders/love.webp"
original_size = File.size(input_path)

puts "📁 Arquivo: #{input_path}"
puts "📊 Tamanho original: #{original_size} bytes (#{(original_size / 1024.0).round(1)}KB)"
puts ""

TARGET_SIZE = 500
target_bytes = TARGET_SIZE * 1024
puts "🎯 Target: #{TARGET_SIZE}KB (#{target_bytes} bytes)"

# O arquivo atual está em 531506 bytes
current_output = 531506
puts "📁 Saída atual: #{current_output} bytes (#{(current_output / 1024.0).round(1)}KB)"
puts "✅ Dentro do target? #{current_output <= target_bytes}"
puts ""

if current_output > target_bytes
  puts "🚨 PROBLEMA: Arquivo está #{current_output - target_bytes} bytes ACIMA do limite!"
  puts "   Isso é #{((current_output - target_bytes) / 1024.0).round(1)}KB a mais"
  puts ""
  
  puts "🔧 AÇÕES NECESSÁRIAS:"
  puts "1. Reduzir mais a qualidade"
  puts "2. Reduzir mais o número de frames"
  puts "3. Verificar se o algoritmo está realmente testando todas as combinações"
  puts ""
  
  # Calcular quantos frames precisamos para ficar no limite
  # Assumindo que o tamanho é proporcional ao número de frames
  current_frames = 25  # Descobrimos que tem 25 frames
  bytes_per_frame = current_output.to_f / current_frames
  max_frames_for_target = (target_bytes / bytes_per_frame).floor
  
  puts "📈 ANÁLISE DE FRAMES:"
  puts "   Frames atuais: #{current_frames}"
  puts "   Bytes por frame: #{bytes_per_frame.round(1)}"
  puts "   Max frames para 500KB: #{max_frames_for_target}"
  puts "   Precisamos reduzir para: #{max_frames_for_target} frames"
end
