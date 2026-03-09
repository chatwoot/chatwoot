#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🚀 TESTE MANUAL: Aplicação de delays compensados"
puts "=" * 60

input_file = "/tmp/debug_delays.webp"
output_file = "/tmp/love_compensated.webp"

# Delays que deveriam ter sido aplicados (compensados)
# Original: 134 frames × 30ms = 4020ms total
# Limitado: 20 frames, então cada frame deve ser: 4020 ÷ 20 = 201ms
compensated_delays = [201] * 20

puts "📊 Aplicando delays compensados:"
puts "   Original: 134 frames × 30ms = 4020ms"
puts "   Novo: 20 frames × 201ms = #{compensated_delays.sum}ms"
puts "   Delays: #{compensated_delays.inspect}"

begin
  # Extrair frames
  puts "\n🔧 ETAPA 1: Extraindo frames individuais..."
  frame_files = []
  
  compensated_delays.each_with_index do |delay, i|
    frame_file = "/tmp/frame_#{i}.webp"
    
    cmd = ["webpmux", "-get", "frame", (i + 1).to_s, input_file, "-o", frame_file]
    stdout, stderr, status = Open3.capture3(*cmd)
    
    if status.success?
      frame_files << { file: frame_file, delay: delay }
      puts "  ✅ Frame #{i + 1} extraído: #{frame_file}"
    else
      puts "  ❌ Falha no frame #{i + 1}: #{stderr}"
      break
    end
  end
  
  puts "\n🔧 ETAPA 2: Recriando animação com delays compensados..."
  
  if frame_files.length == 20
    cmd = ["webpmux"]
    frame_files.each_with_index do |frame_info, i|
      cmd += ["-frame", "#{frame_info[:file]}+#{frame_info[:delay]}"]
    end
    cmd += ["-loop", "0", "-o", output_file]
    
    puts "🔧 Comando webpmux: #{cmd.join(' ')}"
    
    stdout, stderr, status = Open3.capture3(*cmd)
    
    if status.success?
      puts "✅ Animação recriada com sucesso!"
      puts "📁 Arquivo salvo: #{output_file}"
      
      # Verificar o resultado
      puts "\n🔍 VERIFICANDO RESULTADO:"
      
      # Usar webpinfo
      stdout, stderr, status = Open3.capture3("webpinfo", "-summary", output_file)
      if status.success?
        puts "📋 webpinfo output:"
        
        duration_lines = stdout.lines.select { |line| line.include?("Duration:") }
        if duration_lines.any?
          puts "⏱️ DELAYS APLICADOS:"
          duration_lines.each_with_index { |line, i| puts "  Frame #{i + 1}: #{line.strip}" }
          
          # Extrair valores de duration
          durations = duration_lines.map { |line| line.match(/Duration: (\d+)/)[1].to_i }
          total_duration = durations.sum
          puts "🕐 Duração total: #{total_duration}ms"
          
          if total_duration >= 4000 # Próximo ao original de 4020ms
            puts "✅ SUCESSO! Tempo total preservado adequadamente!"
          else
            puts "⚠️ Tempo total ainda não foi preservado adequadamente"
          end
        else
          puts "⚠️ Não foram encontradas informações de duration"
        end
      else
        puts "❌ webpinfo falhou: #{stderr}"
      end
      
    else
      puts "❌ Falha ao recriar animação: #{stderr}"
    end
  else
    puts "❌ Não foi possível extrair todos os frames (obtidos: #{frame_files.length}/20)"
  end
  
rescue => e
  puts "❌ Erro: #{e.class.name}: #{e.message}"
  puts "📋 Backtrace:"
  e.backtrace.first(5).each { |line| puts "  #{line}" }
ensure
  # Cleanup
  puts "\n🧹 Limpando arquivos temporários..."
  frame_files&.each do |frame_info|
    if File.exist?(frame_info[:file])
      File.delete(frame_info[:file])
      puts "  🗑️ Removido: #{frame_info[:file]}"
    end
  end
end

puts "\n🏁 Teste manual finalizado!"
