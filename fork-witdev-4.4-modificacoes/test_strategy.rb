#!/usr/bin/env ruby

require_relative 'config/environment'

Rails.logger.level = Logger::INFO

input_file = "/app/app/uploaders/love.webp"
output_file = "/app/test_strategy.webp"

puts "🔧 TESTE DE ESTRATÉGIA ESPECÍFICA"
puts "=================================="

# Testar uma estratégia específica diretamente
strategy = StickerImageOptimizerService::OPTIMIZATION_STRATEGIES.first
max_frames = 20
original_delays = StickerImageOptimizerService.extract_frame_delays(input_file)
original_total_duration = original_delays.sum

puts "📊 Estratégia: #{strategy[:description]}"
puts "📊 Max frames: #{max_frames}"
puts "📊 Original delays: #{original_delays.length} frames, #{original_total_duration}ms total"

begin
  result = StickerImageOptimizerService.process_animated_with_compensation(
    input_file, 
    output_file, 
    strategy, 
    max_frames,
    original_delays,
    original_total_duration
  )
  
  puts "\n✅ Estratégia result: #{result}"
  
  if File.exist?(output_file)
    size = File.size(output_file)
    puts "📊 Tamanho gerado: #{size} bytes (#{(size/1024.0).round(1)}KB)"
    puts "🎯 Target: 500KB - #{size <= 500*1024 ? 'DENTRO DO LIMITE' : 'MUITO GRANDE'}"
  else
    puts "❌ Arquivo não foi criado"
  end
  
rescue => e
  puts "\n❌ Erro: #{e.class.name}: #{e.message}"
  e.backtrace.first(10).each { |line| puts "  #{line}" }
end
