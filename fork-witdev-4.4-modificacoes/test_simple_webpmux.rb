#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🚀 TESTE SIMPLIFICADO: Aplicação de delays"
puts "=" * 60

input_file = "/tmp/debug_delays.webp"
output_file = "/tmp/love_compensated_simple.webp"

# Teste com menos frames primeiro
test_delays = [201, 201, 201]  # Apenas 3 frames para teste

puts "📊 Testando com 3 frames:"
puts "   Delays: #{test_delays.inspect}"

begin
  # Extrair apenas 3 frames para teste
  puts "\n🔧 ETAPA 1: Extraindo 3 frames..."
  frame_files = []
  
  3.times do |i|
    frame_file = "/tmp/simple_frame_#{i}.webp"
    
    cmd = ["webpmux", "-get", "frame", (i + 1).to_s, input_file, "-o", frame_file]
    stdout, stderr, status = Open3.capture3(*cmd)
    
    if status.success?
      frame_files << { file: frame_file, delay: test_delays[i] }
      puts "  ✅ Frame #{i + 1} extraído: #{frame_file}"
    else
      puts "  ❌ Falha no frame #{i + 1}: #{stderr}"
      break
    end
  end
  
  puts "\n🔧 ETAPA 2: Testando comando webpmux manualmente..."
  
  if frame_files.length == 3
    # Testar comando mais simples
    frame1 = "#{frame_files[0][:file]}+#{frame_files[0][:delay]}"
    frame2 = "#{frame_files[1][:file]}+#{frame_files[1][:delay]}"
    frame3 = "#{frame_files[2][:file]}+#{frame_files[2][:delay]}"
    
    puts "Frame specs:"
    puts "  Frame 1: #{frame1}"
    puts "  Frame 2: #{frame2}"
    puts "  Frame 3: #{frame3}"
    
    cmd = [
      "webpmux",
      "-frame", frame1,
      "-frame", frame2, 
      "-frame", frame3,
      "-loop", "0",
      "-o", output_file
    ]
    
    puts "\n🔧 Comando: #{cmd.join(' ')}"
    
    stdout, stderr, status = Open3.capture3(*cmd)
    
    if status.success?
      puts "✅ Sucesso! Arquivo criado: #{output_file}"
      
      # Verificar resultado
      puts "\n🔍 Verificando delays aplicados..."
      stdout, stderr, status = Open3.capture3("webpinfo", "-summary", output_file)
      if status.success?
        duration_lines = stdout.lines.select { |line| line.include?("Duration:") }
        duration_lines.each_with_index { |line, i| puts "  Frame #{i + 1}: #{line.strip}" }
        
        durations = duration_lines.map { |line| line.match(/Duration: (\d+)/)[1].to_i }
        puts "🕐 Duração total: #{durations.sum}ms (esperado: #{test_delays.sum}ms)"
        
        if durations == test_delays
          puts "✅ PERFEITO! Delays aplicados corretamente!"
        else
          puts "⚠️ Delays diferentes do esperado"
          puts "   Esperado: #{test_delays.inspect}"
          puts "   Obtido: #{durations.inspect}"
        end
      end
      
    else
      puts "❌ Comando falhou: #{stderr}"
      puts "📋 stdout: #{stdout}"
    end
  else
    puts "❌ Não foi possível extrair frames (obtidos: #{frame_files.length}/3)"
  end
  
rescue => e
  puts "❌ Erro: #{e.class.name}: #{e.message}"
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

puts "\n🏁 Teste simplificado finalizado!"
