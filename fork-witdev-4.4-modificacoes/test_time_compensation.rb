#!/usr/bin/env ruby
# frozen_string_literal: true

# Script para testar a lógica de compensação de tempo na otimização de stickers
require_relative 'config/environment'

puts "[TIME-COMPENSATION-TEST] 🧪 Testando lógica de compensação de tempo"

# Simular redução de frames com preservação de tempo total
def test_time_compensation_logic
  puts "\n=== TESTE 1: Redução de 134 frames para 67 frames (metade) ==="
  
  # Dados simulados
  original_frames = 134
  original_delays = Array.new(original_frames, 30) # 30ms por frame = 4020ms total
  original_total = original_delays.sum
  puts "Original: #{original_frames} frames, #{original_total}ms total"
  
  # Simular seleção uniforme para metade dos frames
  max_frames_limit = 67
  indices = (0...original_frames).step(original_frames / max_frames_limit.to_f).map(&:to_i).uniq.first(max_frames_limit)
  selected_delays = indices.map { |i| original_delays[i] }
  
  puts "Após seleção uniforme: #{indices.length} frames, #{selected_delays.sum}ms total"
  
  # Aplicar compensação
  original_frame_count = indices.length
  final_frame_count = indices.length # Neste caso seria o mesmo
  compensation_factor = original_frames.to_f / final_frame_count
  
  compensated_delays = selected_delays.map { |delay| (delay * compensation_factor).round }
  compensated_total = compensated_delays.sum
  
  puts "Compensação aplicada: fator=#{compensation_factor.round(2)}x"
  puts "Resultado: #{final_frame_count} frames, #{compensated_total}ms total"
  puts "Preservação: #{((compensated_total.to_f / original_total) * 100).round(1)}%"
  
  puts "\n=== TESTE 2: Cenário realista com frame culling + limite máximo ==="
  
  # Simular cenário mais realista
  original_frames = 134
  original_delays = Array.new(original_frames, 30)
  original_total = original_delays.sum
  puts "Original: #{original_frames} frames, #{original_total}ms total"
  
  # Simular frame culling (reduziria para digamos 89 frames)
  after_culling = 89
  culled_delays = Array.new(after_culling, 45) # Delays já ajustados pelo culling
  culled_total = culled_delays.sum
  puts "Após frame culling: #{after_culling} frames, #{culled_total}ms total"
  
  # Agora aplicar limite máximo (30 frames)
  max_frames_limit = 30
  indices = (0...after_culling).step(after_culling / max_frames_limit.to_f).map(&:to_i).uniq.first(max_frames_limit)
  selected_delays = indices.map { |i| culled_delays[i] }
  
  puts "Seleção uniforme: #{indices.length} frames selecionados de #{after_culling}"
  
  # Compensação para preservar tempo total do frame culling
  compensation_factor = after_culling.to_f / indices.length
  compensated_delays = selected_delays.map { |delay| (delay * compensation_factor).round }
  final_total = compensated_delays.sum
  
  puts "Compensação: fator=#{compensation_factor.round(2)}x"
  puts "Final: #{indices.length} frames, #{final_total}ms total"
  puts "Preservação vs culled: #{((final_total.to_f / culled_total) * 100).round(1)}%"
  puts "Preservação vs original: #{((final_total.to_f / original_total) * 100).round(1)}%"
  
  puts "\n=== TESTE 3: Delays variáveis (mais realista) ==="
  
  # Delays mais realistas com variação
  original_frames = 100
  original_delays = (1..original_frames).map { |i| 20 + (i % 10) * 5 } # 20-65ms variando
  original_total = original_delays.sum
  puts "Original: #{original_frames} frames, #{original_total}ms total (delays variáveis)"
  puts "Sample delays: #{original_delays.first(10).inspect}"
  
  # Frame culling simulado (manter apenas frames com mudança significativa)
  kept_indices = (0...original_frames).select { |i| i % 3 == 0 } # Simular: manter 1 a cada 3
  culled_delays = kept_indices.map { |i| original_delays[i] }
  # Compensar pela combinação de frames descartados
  culled_delays = culled_delays.map.with_index do |delay, idx|
    start_idx = kept_indices[idx]
    end_idx = kept_indices[idx + 1] || original_frames
    combined_delay = original_delays[start_idx...end_idx].sum
    combined_delay
  end
  
  culled_total = culled_delays.sum
  puts "Após frame culling: #{culled_delays.length} frames, #{culled_total}ms total"
  puts "Sample culled delays: #{culled_delays.first(5).inspect}"
  
  # Limite máximo
  max_frames_limit = 15
  if culled_delays.length > max_frames_limit
    indices = (0...culled_delays.length).step(culled_delays.length / max_frames_limit.to_f).map(&:to_i).uniq.first(max_frames_limit)
    selected_delays = indices.map { |i| culled_delays[i] }
    
    compensation_factor = culled_delays.length.to_f / indices.length
    compensated_delays = selected_delays.map { |delay| (delay * compensation_factor).round }
    final_total = compensated_delays.sum
    
    puts "Limite máximo: #{indices.length} frames selecionados"
    puts "Compensação: fator=#{compensation_factor.round(2)}x"
    puts "Final: #{indices.length} frames, #{final_total}ms total"
    puts "Sample final delays: #{compensated_delays.first(5).inspect}"
    puts "Preservação: #{((final_total.to_f / original_total) * 100).round(1)}%"
  end
end

def test_edge_cases
  puts "\n=== TESTES DE CASOS EXTREMOS ==="
  
  # Caso 1: Muito poucos frames originais
  puts "\nCaso 1: Poucos frames (5 → 3)"
  original_delays = [100, 200, 150, 80, 120]
  original_total = original_delays.sum
  puts "Original: #{original_delays.inspect}, total=#{original_total}ms"
  
  max_limit = 3
  indices = (0...original_delays.length).step(original_delays.length / max_limit.to_f).map(&:to_i).uniq.first(max_limit)
  selected = indices.map { |i| original_delays[i] }
  factor = original_delays.length.to_f / indices.length
  compensated = selected.map { |d| (d * factor).round }
  
  puts "Selecionados: #{selected.inspect} (indices: #{indices.inspect})"
  puts "Compensados: #{compensated.inspect}, total=#{compensated.sum}ms"
  puts "Fator: #{factor.round(2)}x, preservação: #{((compensated.sum.to_f / original_total) * 100).round(1)}%"
  
  # Caso 2: Delays muito pequenos
  puts "\nCaso 2: Delays muito pequenos"
  small_delays = Array.new(50, 10) # 10ms cada
  original_total = small_delays.sum
  puts "Original: 50 frames × 10ms = #{original_total}ms"
  
  max_limit = 20
  indices = (0...small_delays.length).step(small_delays.length / max_limit.to_f).map(&:to_i).uniq.first(max_limit)
  factor = small_delays.length.to_f / indices.length
  compensated = Array.new(indices.length) { (10 * factor).round }
  
  puts "Reduzido para: #{indices.length} frames"
  puts "Delay compensado: #{compensated.first}ms por frame"
  puts "Total: #{compensated.sum}ms, preservação: #{((compensated.sum.to_f / original_total) * 100).round(1)}%"
end

# Executar testes
test_time_compensation_logic
test_edge_cases

puts "\n[TIME-COMPENSATION-TEST] ✅ Testes de compensação de tempo concluídos"
