#!/usr/bin/env ruby

# Script para criar uma animação de teste "love.webp"
# Simula um sticker animado com muitos frames para testar a compensação de tempo

require 'tempfile'

puts '💖 CRIANDO ANIMAÇÃO DE TESTE: love.webp'
puts '=' * 50

# Criar uma animação simples com muitos frames (para forçar redução)
# Usaremos vips para criar uma animação com 100 frames de 100ms cada (10 segundos total)

begin
  # Comando vips para criar uma animação com muitos frames
  # Vamos criar frames coloridos simples
  temp_frames = []
  
  puts "🎞️ Criando 100 frames individuais..."
  
  100.times do |i|
    frame_file = Tempfile.new(['frame', '.png'])
    
    # Criar um frame colorido simples (gradiente baseado no índice)
    hue = (i * 3.6) % 360  # Cada frame muda a cor
    
    # Usar vips para criar um frame com cor sólida e texto
    cmd = "vips text '#{i+1}' /tmp/frame_#{i}.png --fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf --font-size=48 --rgba"
    system(cmd)
    
    # Se o comando anterior falhou, criar frame simples
    unless File.exist?("/tmp/frame_#{i}.png")
      # Criar frame simples com magick
      system("convert -size 200x200 xc:'hsl(#{hue},100%,50%)' -gravity center -pointsize 30 -fill white -annotate +0+0 '#{i+1}' /tmp/frame_#{i}.png")
    end
    
    temp_frames << "/tmp/frame_#{i}.png"
  end
  
  puts "✅ Frames criados. Combinando em animação..."
  
  # Combinar todos os frames em uma animação WebP
  # Cada frame terá 100ms de delay (total = 10 segundos)
  frame_list = temp_frames.join(' ')
  
  output_file = '/tmp/love.webp'
  
  # Usar vips para criar a animação
  cmd = "vips arrayjoin '#{frame_list}' #{output_file} --across 1"
  system(cmd)
  
  # Se vips falhou, tentar com convert
  unless File.exist?(output_file)
    puts "⚠️ Vips falhou, tentando com ImageMagick..."
    system("convert -delay 10 #{frame_list} -loop 0 #{output_file}")
  end
  
  if File.exist?(output_file)
    size = File.size(output_file)
    puts "✅ Animação criada: #{output_file}"
    puts "📊 Tamanho: #{size} bytes (#{(size / 1024.0).round(1)}KB)"
    puts "🎞️ 100 frames × 100ms = 10 segundos total"
  else
    puts "❌ Falha ao criar animação"
  end
  
rescue => e
  puts "❌ ERRO: #{e.message}"
ensure
  # Limpar frames temporários
  puts "🧹 Limpando frames temporários..."
  temp_frames.each do |frame|
    File.delete(frame) if File.exist?(frame)
  end
  
  # Limpar frames numerados
  100.times do |i|
    frame_path = "/tmp/frame_#{i}.png"
    File.delete(frame_path) if File.exist?(frame_path)
  end
end

puts "🏁 Script finalizado!"
