#!/usr/bin/env ruby

require_relative 'config/environment'

input_file = "/app/app/uploaders/love.webp"

puts "🔍 TESTE DE DETECÇÃO DE ANIMAÇÃO"
puts "================================="
puts "📁 Arquivo: #{input_file}"
puts "🎬 É animado? #{StickerImageOptimizerService.animated_webp?(input_file)}"

# Testar a detecção com webpinfo diretamente
puts "\n📋 Webpinfo direto:"
system("webpinfo", input_file)
