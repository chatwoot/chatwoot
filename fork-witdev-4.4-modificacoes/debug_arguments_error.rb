#!/usr/bin/env ruby

require_relative '/app/config/environment'

puts "🔍 Debug específico do erro wrong number of arguments"

class TestFile
  attr_reader :size, :content_type
  def initialize(file_path)
    @path = file_path
    @size = File.size(file_path)
    @content_type = 'image/jpeg'
  end
  def read; File.binread(@path); end
  def rewind; end
  def respond_to?(method); [:read, :rewind, :size, :content_type].include?(method); end
end

begin
  file_path = '/app/app/uploaders/foto.jpg'
  test_file = TestFile.new(file_path)
  
  puts "1. Criando service..."
  service = StickerImageOptimizerService.new(file: test_file, account_id: 3)
  
  puts "2. Validando input..."
  service.send(:validate_input!)
  
  puts "3. Validando dependências..."
  service.send(:validate_system_dependencies!)
  
  puts "4. Executando processo..."
  result = service.process
  
  puts "✅ Resultado: success=#{result[:success]}"
  if result[:success]
    puts "   Final size: #{result[:final_size]} bytes"
  else
    puts "   Erro: #{result[:error]}"
  end
  
rescue => e
  puts "❌ Erro: #{e.message}"
  puts "📍 Classe: #{e.class.name}"
  puts "📋 Backtrace:"
  e.backtrace.first(10).each { |line| puts "   #{line}" }
end
