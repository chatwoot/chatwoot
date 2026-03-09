#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'
require 'open3'

puts '🎬 ANÁLISE DE TIMING DE ANIMAÇÃO'
puts '=' * 50

def analyze_webp_timing(file_path, label)
  puts "\n📁 Analisando: #{label}"
  puts "   Arquivo: #{file_path}"
  
  # Verificar se arquivo existe
  unless File.exist?(file_path)
    puts "   ❌ Arquivo não encontrado!"
    return
  end
  
  file_size = File.size(file_path)
  puts "   📊 Tamanho: #{file_size} bytes (#{(file_size / 1024.0).round(1)}KB)"
  
  # Usar webpinfo para extrair informações detalhadas
  stdout, stderr, status = Open3.capture3("webpinfo", file_path)
  
  unless status.success?
    puts "   ❌ Erro ao executar webpinfo: #{stderr}"
    return
  end
  
  # Extrair informações principais
  lines = stdout.split("\n")
  
  # Procurar por informações de animação
  canvas_size = lines.find { |l| l.include?("Canvas size") }
  frames_info = lines.select { |l| l.include?("Duration:") || l.include?("Frame") }
  animation_info = lines.find { |l| l.include?("Features present") }
  
  puts "   🖼️  #{canvas_size}" if canvas_size
  puts "   🎞️  #{animation_info}" if animation_info
  
  # Extrair durações dos frames
  durations = []
  current_frame = nil
  
  lines.each do |line|
    if line.match(/Chunk ANMF at offset (\d+), length (\d+)/)
      current_frame = line
    elsif line.match(/Duration: (\d+)/)
      duration = line.match(/Duration: (\d+)/)[1].to_i
      durations << duration
      puts "   ⏱️  Frame #{durations.length}: #{duration}ms"
    end
  end
  
  if durations.any?
    total_duration = durations.sum
    avg_duration = durations.sum.to_f / durations.length
    min_duration = durations.min
    max_duration = durations.max
    
    puts "\n   📈 ESTATÍSTICAS DE TIMING:"
    puts "      🔢 Total de frames: #{durations.length}"
    puts "      ⏱️  Duração total: #{total_duration}ms (#{(total_duration / 1000.0).round(2)}s)"
    puts "      📊 Duração média: #{avg_duration.round(2)}ms"
    puts "      ⬇️  Duração mínima: #{min_duration}ms"
    puts "      ⬆️  Duração máxima: #{max_duration}ms"
    puts "      🔄 FPS efetivo: #{(1000.0 / avg_duration).round(2)} fps"
    
    # Verificar consistência
    unique_durations = durations.uniq
    if unique_durations.length == 1
      puts "      ✅ Timing consistente: todos os frames têm #{unique_durations.first}ms"
    else
      puts "      ⚠️  Timing variável: #{unique_durations.length} durações diferentes"
      puts "      📋 Durações únicas: #{unique_durations.sort.join(', ')}ms"
    end
  else
    puts "   ❌ Não foi possível extrair informações de timing"
  end
  
  durations
end

begin
  # Analisar arquivo original
  original_file = '/app/app/uploaders/love.webp'
  original_durations = analyze_webp_timing(original_file, "ARQUIVO ORIGINAL")
  
  # Procurar arquivo otimizado mais recente
  optimized_files = Dir.glob('/app/app/uploaders/sticker_end2end_*.webp').sort_by { |f| File.mtime(f) }
  
  if optimized_files.any?
    latest_optimized = optimized_files.last
    optimized_durations = analyze_webp_timing(latest_optimized, "ARQUIVO OTIMIZADO")
    
    # Comparação detalhada
    if original_durations.any? && optimized_durations.any?
      puts "\n🔍 COMPARAÇÃO DETALHADA:"
      puts "=" * 30
      
      puts "📊 Quantidade de frames:"
      puts "   Original: #{original_durations.length} frames"
      puts "   Otimizado: #{optimized_durations.length} frames"
      
      if original_durations.length != optimized_durations.length
        puts "   ⚠️  DIFERENÇA: #{(original_durations.length - optimized_durations.length).abs} frames de diferença"
      else
        puts "   ✅ Mesmo número de frames"
      end
      
      puts "\n⏱️  Timing por frame:"
      max_frames = [original_durations.length, optimized_durations.length].max
      
      differences = []
      
      (0...max_frames).each do |i|
        orig_duration = original_durations[i] || 0
        opt_duration = optimized_durations[i] || 0
        
        if orig_duration != 0 && opt_duration != 0
          diff = opt_duration - orig_duration
          differences << diff
          status = diff == 0 ? "✅" : (diff.abs <= 10 ? "⚠️" : "❌")
          puts "   Frame #{i+1}: #{orig_duration}ms → #{opt_duration}ms (#{diff > 0 ? '+' : ''}#{diff}ms) #{status}"
        elsif orig_duration != 0
          puts "   Frame #{i+1}: #{orig_duration}ms → REMOVIDO ❌"
        elsif opt_duration != 0
          puts "   Frame #{i+1}: NOVO → #{opt_duration}ms ⚠️"
        end
      end
      
      if differences.any?
        avg_diff = differences.sum.to_f / differences.length
        puts "\n📈 RESUMO DAS DIFERENÇAS:"
        puts "   📊 Diferença média: #{avg_diff.round(2)}ms"
        puts "   ⬇️  Menor diferença: #{differences.min}ms"
        puts "   ⬆️  Maior diferença: #{differences.max}ms"
        
        if differences.all? { |d| d.abs <= 10 }
          puts "   ✅ TIMING PRESERVADO: Diferenças mínimas (≤10ms)"
        elsif differences.all? { |d| d.abs <= 50 }
          puts "   ⚠️  TIMING LEVEMENTE ALTERADO: Diferenças pequenas (≤50ms)"
        else
          puts "   ❌ TIMING SIGNIFICATIVAMENTE ALTERADO: Diferenças grandes (>50ms)"
        end
      end
      
      # Calcular velocidade de reprodução
      orig_total = original_durations.sum
      opt_total = optimized_durations.sum
      
      if orig_total > 0 && opt_total > 0
        speed_ratio = opt_total.to_f / orig_total
        puts "\n🎬 VELOCIDADE DE REPRODUÇÃO:"
        puts "   Original: #{(orig_total / 1000.0).round(2)}s total"
        puts "   Otimizado: #{(opt_total / 1000.0).round(2)}s total"
        puts "   Ratio: #{speed_ratio.round(3)}x"
        
        if speed_ratio < 0.9
          puts "   🔥 MAIS RÁPIDO: #{((1 - speed_ratio) * 100).round(1)}% mais rápido"
        elsif speed_ratio > 1.1
          puts "   🐌 MAIS LENTO: #{((speed_ratio - 1) * 100).round(1)}% mais lento"
        else
          puts "   ✅ VELOCIDADE PRESERVADA: Diferença < 10%"
        end
      end
    end
  else
    puts "\n❌ Nenhum arquivo otimizado encontrado para comparação"
    puts "   Procurando em: /app/app/uploaders/sticker_end2end_*.webp"
  end
  
rescue => e
  puts "❌ ERRO: #{e.message}"
  puts "📋 Backtrace:"
  e.backtrace.first(5).each { |line| puts "   #{line}" }
end

puts "\n🏁 Análise finalizada!"
