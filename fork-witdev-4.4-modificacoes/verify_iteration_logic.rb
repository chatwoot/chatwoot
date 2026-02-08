#!/usr/bin/env ruby

puts "🔍 VERIFICAÇÃO DA LÓGICA DE ITERAÇÕES"
puts "=" * 50

QUALITY_LEVELS = [75, 65, 55, 45, 35, 25]
base_cull_threshold = 5.0

puts "📊 LÓGICA IMPLEMENTADA:"
QUALITY_LEVELS.each_with_index do |quality_level, index|
  cull_threshold = base_cull_threshold + (index * 2.0)
  
  if index == 0
    max_frames = Float::INFINITY
    puts "   Iteração #{index + 1}: Q#{quality_level}% | Cull #{cull_threshold} | max_frames = #{max_frames}"
    puts "     ➜ SEM LIMITE DE FRAMES (preserva todos após culling)"
  else
    max_frames = index == 1 ? 30 : (index < 4 ? 20 : 15)
    puts "   Iteração #{index + 1}: Q#{quality_level}% | Cull #{cull_threshold} | max_frames = #{max_frames}"
    puts "     ➜ COM LIMITE DE FRAMES"
  end
end

puts
puts "🎯 EXPECTATIVA PARA O STICKER DE TESTE:"
puts "   Frames originais: 40"
puts "   Iteração 1: Q75% + culling only (max_frames = ∞)"
puts "   Resultado esperado: ~35-39 frames (após culling)"
puts "   Tamanho estimado: pode ser > 500KB, forçando Iteração 2"
puts
puts "   Iteração 2: Q65% + culling + limite 30 frames"
puts "   Resultado esperado: 30 frames (após limite)"

puts
puts "🚨 PROBLEMA IDENTIFICADO:"
puts "   Se Iteração 1 resultou em exatamente 30 frames,"
puts "   significa que o limite foi aplicado incorretamente!"
