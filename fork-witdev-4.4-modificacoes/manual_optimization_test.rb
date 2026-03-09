#!/usr/bin/env ruby

require 'vips'

puts "🔧 TESTE ISOLADO - PROCESSO MANUAL DE OTIMIZAÇÃO"
puts "================================================"

input_path = "/app/app/uploaders/love.webp"
output_path = "/tmp/manual_optimization_test.webp"

original_size = File.size(input_path)
puts "📁 Original: #{original_size} bytes (#{(original_size / 1024.0).round(1)}KB)"

TARGET_SIZE = 500
target_bytes = TARGET_SIZE * 1024

# Testar manualmente algumas combinações específicas
test_combinations = [
  { quality: 65, max_frames: 25, description: "65% quality, 25 frames" },
  { quality: 65, max_frames: 24, description: "65% quality, 24 frames" },
  { quality: 55, max_frames: 24, description: "55% quality, 24 frames" },
  { quality: 45, max_frames: 24, description: "45% quality, 24 frames" },
  { quality: 35, max_frames: 20, description: "35% quality, 20 frames" },
]

test_combinations.each_with_index do |combo, index|
  puts "\n🧪 TESTE #{index + 1}: #{combo[:description]}"
  
  begin
    # Carregar animação
    animation = Vips::Image.new_from_file(input_path, n: -1)
    n_pages = animation.get('n-pages')
    page_height = animation.height / n_pages
    
    puts "   📊 Frames originais: #{n_pages}"
    
    # Selecionar frames (simples: primeiros N frames)
    max_frames = [combo[:max_frames], n_pages].min
    selected_frames = (0...max_frames).to_a
    
    puts "   🎯 Frames selecionados: #{max_frames}"
    
    # Extrair e processar frames
    frames = []
    selected_frames.each do |frame_index|
      frame = animation.crop(0, frame_index * page_height, animation.width, page_height)
      frame = frame.thumbnail_image(512, height: 512, crop: :centre)
      frames << frame
    end
    
    # Reconstroi a tira de filme
    animation_strip = Vips::Image.arrayjoin(frames, across: 1)
    
    # Aplicar metadados básicos
    delays = Array.new(max_frames, 30)  # 30ms por frame
    animation_strip = animation_strip.copy(
      interpretation: :srgb,
      delay: delays,
      loop: 0
    )
    
    # Salvar
    kmax = [max_frames / 4, 1].max
    animation_strip.webpsave(output_path, 
      page_height: 512,
      Q: combo[:quality],
      lossless: false,
      kmax: kmax,
      effort: 4
    )
    
    output_size = File.size(output_path)
    success = output_size <= target_bytes
    
    puts "   📊 Resultado: #{output_size} bytes (#{(output_size / 1024.0).round(1)}KB)"
    puts "   🎯 Target: #{success ? '✅ DENTRO' : '❌ FORA'} do limite"
    puts "   💾 Redução: #{((original_size - output_size).to_f / original_size * 100).round(1)}%"
    
    if success
      puts "   🎉 SUCESSO! Esta combinação funciona!"
      break
    end
    
  rescue => e
    puts "   ❌ ERRO: #{e.message}"
  end
end

puts "\n🏁 Teste manual finalizado!"
