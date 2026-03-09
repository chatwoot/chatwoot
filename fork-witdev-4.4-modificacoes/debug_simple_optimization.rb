#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

puts '🔍 DEBUG: Investigando erro na otimização'
puts '=' * 50

begin
  file_path = '/app/app/uploaders/teste-stiker.webp'
  puts "📁 Arquivo: #{file_path}"
  puts "📊 Tamanho: #{File.size(file_path)} bytes"
  
  # Criar objeto file simples
  file_obj = File.open(file_path, 'rb')
  
  puts "✅ Arquivo aberto"
  
  # Criar service
  optimizer = StickerImageOptimizerService.new(file: file_obj, account_id: 3)
  puts "✅ Service criado"
  
  # Executar com logs detalhados
  puts "\n🚀 Executando otimização..."
  result = optimizer.process
  
  puts "\n📊 RESULTADO:"
  puts "   Success: #{result[:success]}"
  if result[:success]
    puts "   Final size: #{result[:final_size]} bytes"
    puts "   Compression: #{result[:compression_ratio]}%"
    puts "   Method: #{result[:method]}"
  else
    puts "   Error: #{result[:error]}"
  end
  
  file_obj.close
  
rescue => e
  puts "❌ ERRO: #{e.message}"
  puts "📍 Class: #{e.class.name}"
  puts "📋 Backtrace:"
  e.backtrace.first(10).each { |line| puts "   #{line}" }
end
