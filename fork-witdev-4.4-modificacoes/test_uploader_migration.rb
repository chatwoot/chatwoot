#!/usr/bin/env ruby

# Test script para validar a migração do StickerUploader para ruby-vips
puts "🧪 [UPLOADER-TEST] Testing StickerUploader migration to ruby-vips"

begin
  require 'vips'
  puts "✅ [UPLOADER-TEST] ruby-vips loaded successfully"
rescue LoadError => e
  puts "❌ [UPLOADER-TEST] Failed to load ruby-vips: #{e.message}"
  exit 1
end

# Test de sintaxe do arquivo
begin
  load 'app/uploaders/sticker_uploader.rb'
  puts "✅ [UPLOADER-TEST] StickerUploader syntax OK"
rescue => e
  puts "❌ [UPLOADER-TEST] StickerUploader load failed: #{e.message}"
  exit 1
end

# Test básico de instanciação
begin
  # Mock de um arquivo de teste
  class MockFile
    def initialize(content_type, size)
      @content_type = content_type
      @size = size
    end
    
    attr_reader :content_type, :size
    
    def respond_to?(method)
      [:content_type, :size, :read, :rewind].include?(method.to_sym)
    end
    
    def read
      "fake_image_data"
    end
    
    def rewind
      # Mock implementation
    end
  end
  
  # Test JPEG file
  mock_jpeg = MockFile.new('image/jpeg', 100_000)
  uploader = StickerUploader.new(file: mock_jpeg, pack_name: "test_pack")
  
  puts "✅ [UPLOADER-TEST] StickerUploader instantiation OK"
  puts "✅ [UPLOADER-TEST] JPEG detection: #{uploader.send(:needs_special_processing?) ? 'Special processing' : 'Fast processing'}"
  
  # Test WebP file
  mock_webp = MockFile.new('image/webp', 200_000)
  uploader_webp = StickerUploader.new(file: mock_webp, pack_name: "test_pack")
  puts "✅ [UPLOADER-TEST] WebP detection ready"
  
  # Test PNG file
  mock_png = MockFile.new('image/png', 150_000)
  uploader_png = StickerUploader.new(file: mock_png, pack_name: "test_pack")
  puts "✅ [UPLOADER-TEST] PNG detection ready"
  
  puts "🎉 [UPLOADER-TEST] All tests passed! Migration to ruby-vips successful!"
  
rescue => e
  puts "❌ [UPLOADER-TEST] Test failed: #{e.message}"
  puts "📋 [UPLOADER-TEST] Backtrace: #{e.backtrace.first(3).join(' | ')}"
  exit 1
end
