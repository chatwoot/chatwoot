#!/usr/bin/env ruby
require_relative 'config/environment'

# Teste da lógica de compensação de tempo isoladamente
puts "=== TESTE DE COMPENSAÇÃO DE TEMPO ==="
puts

# Simular dados reais
original_delays = Array.new(134, 30)  # 134 frames de 30ms cada
original_total = original_delays.sum  # 4020ms total
puts "📊 Original: #{original_delays.length} frames, #{original_total}ms total"

# Simular redução para diferentes números de frames
[50, 30, 20, 15].each do |target_frames|
  puts "\n🎯 Reduzindo para #{target_frames} frames:"
  
  # Calcular fator de compensação
  compensation_factor = original_delays.length.to_f / target_frames
  puts "  📈 Fator de compensação: #{compensation_factor.round(2)}x"
  
  # Delays compensados
  base_delay = original_delays.first * compensation_factor
  compensated_delays = Array.new(target_frames, base_delay.round)
  compensated_total = compensated_delays.sum
  
  puts "  ⏰ Novo delay por frame: #{base_delay.round}ms"
  puts "  ⏰ Tempo total preservado: #{compensated_total}ms"
  puts "  📊 Preservação: #{((compensated_total.to_f / original_total) * 100).round(1)}%"
  
  # Verificar se está próximo do original (tolerância de ±2%)
  preservation = (compensated_total.to_f / original_total) * 100
  if preservation >= 98 && preservation <= 102
    puts "  ✅ COMPENSAÇÃO OK!"
  else
    puts "  ❌ Compensação fora da tolerância"
  end
end

puts "\n=== TESTE COM ARQUIVO REAL ==="

# Testar com arquivo real
input_file = 'app/uploaders/love.webp'
if File.exist?(input_file)
  image = Vips::Image.new_from_file(input_file, n: -1)
  real_delays = image.get('delay')
  real_total = real_delays.sum
  
  puts "📂 Arquivo: #{input_file}"
  puts "📊 Real: #{real_delays.length} frames, #{real_total}ms total"
  puts "📊 Delays sample: #{real_delays.first(5).inspect}"
  
  # Testar compensação para 20 frames
  target = 20
  factor = real_delays.length.to_f / target
  compensated = Array.new(target, (real_delays.first * factor).round)
  
  puts "\n🎯 Compensação para #{target} frames:"
  puts "  📈 Fator: #{factor.round(2)}x"
  puts "  ⏰ Novo delay: #{compensated.first}ms por frame"
  puts "  ⏰ Total preservado: #{compensated.sum}ms (era #{real_total}ms)"
  puts "  📊 Preservação: #{((compensated.sum.to_f / real_total) * 100).round(1)}%"
  
else
  puts "❌ Arquivo #{input_file} não encontrado"
end

puts "\n✅ Teste de compensação finalizado!"
