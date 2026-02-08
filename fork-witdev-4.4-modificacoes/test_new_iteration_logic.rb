#!/usr/bin/env ruby

# Test script para verificar a nova lógica de iterações
# Iteração 1: Apenas culling threshold (sem limite de frames)
# Iteração 2+: Aplicar limite de frames

puts "🧪 TESTE: Nova Lógica de Iterações"
puts "=" * 50

# Simular os parâmetros do sticker dos logs
original_frames = 60
original_delays = Array.new(60, 39) # 60 frames com 39ms cada
base_cull_threshold = 5.0
quality_levels = [75, 65, 55, 45, 35, 25]

puts "📊 DADOS ORIGINAIS:"
puts "   Frames: #{original_frames}"
puts "   Delays: #{original_delays.first(5).inspect} (sample)"
puts "   Total duration: #{original_delays.sum}ms"
puts

quality_levels.each_with_index do |quality_level, index|
  puts "🎯 ITERAÇÃO #{index + 1}: Qualidade #{quality_level}%"
  
  # Calcular threshold de culling (aumenta a cada iteração)
  cull_threshold = base_cull_threshold + (index * 2.0)
  
  # NOVA LÓGICA: Iteração 1 vs 2+
  if index == 0
    max_frames = Float::INFINITY
    puts "   Strategy: Apenas culling threshold (#{cull_threshold}), SEM limite de frames"
  else
    max_frames = index == 1 ? 30 : (index < 4 ? 20 : 15)
    puts "   Strategy: Culling threshold (#{cull_threshold}) + limite de frames (#{max_frames})"
  end
  
  # Simular resultado do culling (baseado nos logs reais)
  if index == 0
    # Iteração 1: culling removeu apenas 1 frame (60 → 59)
    frames_after_culling = 59
    culled_frames = 1
    puts "   Culling result: #{original_frames} → #{frames_after_culling} frames (#{culled_frames} culled)"
    
    # Verificar se precisa aplicar limite
    if max_frames != Float::INFINITY && frames_after_culling > max_frames
      final_frames = max_frames
      puts "   Frame limit applied: #{frames_after_culling} → #{final_frames} frames"
    else
      final_frames = frames_after_culling
      puts "   No frame limit applied: keeping #{final_frames} frames"
    end
  else
    # Iterações 2+: culling mais agressivo + limite
    frames_after_culling = [original_frames - (index * 5), 10].max # Simular culling mais agressivo
    
    if frames_after_culling > max_frames
      final_frames = max_frames
      puts "   Culling + Limit: #{original_frames} → #{frames_after_culling} → #{final_frames} frames"
    else
      final_frames = frames_after_culling
      puts "   Culling only: #{original_frames} → #{final_frames} frames"
    end
  end
  
  # Calcular tamanho estimado (baseado na qualidade e número de frames)
  base_size = 369102 # Tamanho original dos logs
  quality_factor = quality_level / 100.0
  frame_factor = final_frames / original_frames.to_f
  estimated_size = (base_size * quality_factor * frame_factor).to_i
  
  puts "   Estimated size: ~#{estimated_size} bytes"
  
  # Verificar se está dentro do limite do WhatsApp (500KB)
  whatsapp_limit = 500 * 1024
  if estimated_size <= whatsapp_limit
    puts "   ✅ SUCCESS! Within WhatsApp limit (#{estimated_size} ≤ #{whatsapp_limit})"
    puts
    break
  else
    puts "   ⚠️  Still too large (#{estimated_size} > #{whatsapp_limit}), trying next iteration..."
  end
  
  puts
end

puts "🎯 VANTAGENS DA NOVA LÓGICA:"
puts "1. Iteração 1 preserva máxima qualidade visual (59 frames vs 30)"
puts "2. Usa apenas culling inteligente (remove frames similares)"
puts "3. Só força limite se necessário para atingir tamanho"
puts "4. Melhor chance de sucesso na primeira iteração"
