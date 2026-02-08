#!/usr/bin/env ruby

puts "🔧 TESTE ISOLADO - VERIFICAR LOOPS DE OTIMIZAÇÃO"
puts "=================================================="

input_path = "/app/app/uploaders/love.webp"

puts "📁 Arquivo de entrada: #{input_path}"
puts "📊 Tamanho original: #{File.size(input_path)} bytes (#{(File.size(input_path) / 1024.0).round(1)}KB)"
puts ""

# Simular as condições do método optimize_animated_sticker
TARGET_SIZE = 500 # 500KB limit
OPTIMIZATION_STRATEGIES = [
  { quality: 65, size: 512, description: "65% quality, 512x512" },
  { quality: 55, size: 512, description: "55% quality, 512x512" },
  { quality: 45, size: 512, description: "45% quality, 512x512" },
  { quality: 35, size: 512, description: "35% quality, 512x512" },
  { quality: 25, size: 512, description: "25% quality, 512x512" },
  { quality: 15, size: 512, description: "15% quality, 512x512" }
]

PROGRESSIVE_FRAME_LIMITS = [80, 60, 45, 35, 25, 20]

puts "🎯 TARGET_SIZE: #{TARGET_SIZE}KB (#{TARGET_SIZE * 1024} bytes)"
puts "🔧 STRATEGIES: #{OPTIMIZATION_STRATEGIES.length} estratégias"
puts "📈 FRAME_LIMITS: #{PROGRESSIVE_FRAME_LIMITS.inspect}"
puts ""

# Verificar qual combinação seria tentada primeiro
OPTIMIZATION_STRATEGIES.each_with_index do |strategy, strategy_index|
  puts "ESTRATÉGIA #{strategy_index + 1}: #{strategy[:description]}"
  
  PROGRESSIVE_FRAME_LIMITS.each_with_index do |max_frames, limit_index|
    puts "  Frame Limit #{limit_index + 1}: max #{max_frames} frames"
    
    # Esta seria a primeira combinação testada
    if strategy_index == 0 && limit_index == 0
      puts "    >>> ESTA É A PRIMEIRA COMBINAÇÃO TESTADA! <<<"
      puts "    Se ela 'funcionar' (não dar erro), vai retornar mesmo que > 500KB"
    end
  end
  puts ""
end

puts "🚨 PROBLEMA IDENTIFICADO:"
puts "O método retorna SUCCESS na primeira estratégia que não dá erro,"
puts "mesmo que o arquivo seja > 500KB!"
puts ""
puts "🔧 SOLUÇÃO NECESSÁRIA:"
puts "Verificar se output_size <= TARGET_SIZE * 1024 DENTRO do loop"
puts "em vez de só verificar se o processamento foi bem-sucedido."
