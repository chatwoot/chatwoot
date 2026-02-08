#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== Teste Manual de Delays ==="

# Usar o arquivo love.webp existente
input_file = 'app/uploaders/love.webp'
output_file = 'love_manual_test.webp'

# Limpar arquivo de saída anterior
File.delete(output_file) if File.exist?(output_file)

puts "📂 Input: #{input_file}"
puts "📂 Output: #{output_file}"

# Carregar a imagem
image = Vips::Image.new_from_file(input_file, n: -1)
puts "📊 Original: #{image.width}x#{image.height}, #{image.get('n-pages')} frames"

# Extrair frames
n_pages = image.get('n-pages')
page_height = image.get('page-height')
original_delays = image.get('delay')

puts "📊 Original delays: #{original_delays.inspect}"
puts "📊 Total duration: #{original_delays.sum}ms"

# Extrair apenas os primeiros 20 frames
frames = (0...20).map do |i|
  crop_y = i * page_height
  image.crop(0, crop_y, image.width, page_height)
end

# Criar array manual de delays compensados
# Se tínhamos 134 frames com delays de ~30ms cada (total ~4020ms)
# Agora com 20 frames, cada frame deve ter ~201ms para manter o tempo total
target_total_duration = original_delays.sum
frames_count = 20
compensated_delay = target_total_duration / frames_count

# Array manual de 20 delays compensados
manual_delays = Array.new(20, compensated_delay.round)

puts "📊 Manual delays: #{manual_delays.inspect}"
puts "📊 New total duration: #{manual_delays.sum}ms"
puts "📊 Compensation factor: #{compensated_delay / original_delays.first}x"

# Redimensionar frames para 512x512
resized_frames = frames.map do |frame|
  frame.thumbnail_image(512, height: 512, crop: :centre)
end

puts "🎞️ Creating filmstrip with #{resized_frames.length} frames..."

# Criar a tira de filme
animation_strip = Vips::Image.arrayjoin(resized_frames, across: 1)

puts "🎞️ Filmstrip: #{animation_strip.width}x#{animation_strip.height}"

# TESTE: Salvar com delays manuais usando metadados
begin
  # Anotar metadados antes de salvar (sintaxe correta do libvips)
  animation_strip = animation_strip.copy
  animation_strip.set("page-height", 512)
  animation_strip.set("n-pages", 20) 
  animation_strip.set("loop", 0)
  animation_strip.set("delay", manual_delays)
  
  puts "✅ Metadados anotados na imagem"
  
  # Salvar
  animation_strip.webpsave(output_file, 
    page_height: 512,
    Q: 75,
    lossless: false,
    effort: 4
  )
  
  puts "✅ Arquivo salvo: #{output_file}"
  
  # Verificar o resultado
  if File.exist?(output_file)
    result_image = Vips::Image.new_from_file(output_file, n: -1)
    result_delays = result_image.get('delay')
    
    puts "🔍 RESULTADO:"
    puts "📊 Frames: #{result_image.get('n-pages')}"
    puts "📊 Result delays: #{result_delays.inspect}"
    puts "📊 Result total duration: #{result_delays.sum}ms"
    puts "📊 Size: #{File.size(output_file)} bytes"
    
    # Comparar com original
    puts "\n📋 COMPARAÇÃO:"
    puts "Original: #{n_pages} frames, #{original_delays.sum}ms total"
    puts "Resultado: #{result_image.get('n-pages')} frames, #{result_delays.sum}ms total"
    puts "Preservação de tempo: #{((result_delays.sum.to_f / original_delays.sum) * 100).round(1)}%"
  end
  
rescue => e
  puts "❌ ERRO: #{e.message}"
  puts "📋 Backtrace: #{e.backtrace.first(3).join(' | ')}"
end
