#!/usr/bin/env ruby

require_relative '/app/config/environment'

puts "🔍 DEBUG DETALHADO: Verificando se Iteração 1 aplica limite"
puts "=" * 60

class TestFile
  attr_reader :size, :content_type
  
  def initialize(file_path)
    @path = file_path
    @size = File.size(file_path)
    @content_type = 'image/webp'
  end
  
  def read
    File.binread(@path)
  end
  
  def rewind
  end
  
  def respond_to?(method)
    [:read, :rewind, :size, :content_type].include?(method)
  end
end

begin
  file_path = '/app/app/uploaders/teste-stiker.webp'
  file_obj = TestFile.new(file_path)
  
  puts "📁 Arquivo: #{file_path}"
  puts "📊 Tamanho: #{file_obj.size} bytes"
  
  # Interceptar logs para capturar o comportamento
  original_logger = Rails.logger
  log_buffer = []
  
  logger_mock = Object.new
  def logger_mock.info(msg)
    puts msg
    @log_buffer ||= []
    @log_buffer << msg
  end
  def logger_mock.warn(msg)
    puts msg  
    @log_buffer ||= []
    @log_buffer << msg
  end
  def logger_mock.error(msg)
    puts msg
    @log_buffer ||= []
    @log_buffer << msg
  end
  def logger_mock.debug(msg)
    puts msg
    @log_buffer ||= []
    @log_buffer << msg
  end
  
  Rails.logger = logger_mock
  
  puts "\n🚀 EXECUTANDO COM LOGS DETALHADOS..."
  puts "=" * 40
  
  optimizer = StickerImageOptimizerService.new(file: file_obj, account_id: 3)
  result = optimizer.process
  
  Rails.logger = original_logger
  
  puts "\n📊 RESULTADO:"
  puts "   Success: #{result[:success]}"
  if result[:success]
    puts "   Final size: #{result[:final_size]} bytes"
    puts "   Method: #{result[:method]}"
  end
  
  file_obj.close
  
rescue => e
  Rails.logger = original_logger if original_logger
  puts "❌ ERRO: #{e.message}"
end
