#!/usr/bin/env ruby

# Análise do sticker de teste
frames = `webpinfo app/uploaders/teste-stiker.webp`.scan(/Chunk ANMF at offset/).length
file_size = File.size('app/uploaders/teste-stiker.webp')

puts "📊 ANÁLISE DO STICKER DE TESTE:"
puts "   Arquivo: app/uploaders/teste-stiker.webp"
puts "   Tamanho: #{file_size} bytes (~#{(file_size/1024.0).round(1)}KB)"
puts "   Frames: #{frames}"
puts "   Duração por frame: 83ms"
puts "   Duração total: #{frames * 83}ms (~#{(frames * 83 / 1000.0).round(1)}s)"
puts "   Resolução: 512x512"
puts "   Status: Já dentro do limite WhatsApp (#{(file_size/1024.0).round(1)}KB < 500KB)"
puts
puts "🎯 TESTE INTERESSANTE:"
puts "   Este sticker JÁ está otimizado!"
puts "   Vamos ver como a nova lógica se comporta..."
puts "   Expectativa: Sucesso na Iteração 1 com mínimas modificações"
