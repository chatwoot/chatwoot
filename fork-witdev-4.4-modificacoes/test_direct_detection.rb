#!/usr/bin/env ruby

require_relative 'config/environment'

input_file = "/app/app/uploaders/love.webp"

puts "🔍 TESTE DE DETECÇÃO DE ANIMAÇÃO"
puts "================================="
puts "📁 Arquivo: #{input_file}"

# Testar o método diretamente
is_animated = StickerImageOptimizerService.animated_webp?(input_file)
puts "🎬 É animado? #{is_animated}"

# Se não for detectado como animado, vamos ao método de estática
if !is_animated
  puts "\n🔧 Testando otimização estática..."
  result = StickerImageOptimizerService.optimize_static_sticker(input_file, "/app/test_static_output.webp")
  puts "📊 Resultado estático: #{result}"
else
  puts "\n🔧 Testando otimização animada..."
  result = StickerImageOptimizerService.optimize_animated_sticker(input_file, "/app/test_animated_output.webp")
  puts "📊 Resultado animado: #{result}"
end
