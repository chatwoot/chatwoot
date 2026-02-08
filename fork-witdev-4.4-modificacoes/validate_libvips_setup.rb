#!/usr/bin/env ruby
# frozen_string_literal: true

# Script para validar se a nova implementação libvips está funcionando
# Execute: ruby validate_libvips_setup.rb

puts "🔍 VALIDANDO SETUP LIBVIPS PARA STICKERS"
puts "=" * 50

# Teste 1: Verificar se as ferramentas WebP estão disponíveis
puts "\n1️⃣ Verificando ferramentas WebP..."
required_tools = %w[webpinfo webpmux img2webp]

tools_available = required_tools.all? do |tool|
  result = system("which #{tool} > /dev/null 2>&1")
  puts "   #{result ? '✅' : '❌'} #{tool}"
  result
end

# Teste 2: Verificar ruby-vips
puts "\n2️⃣ Verificando ruby-vips..."
begin
  require 'vips'
  version = Vips.version_string
  puts "   ✅ ruby-vips disponível: #{version}"
  vips_available = true
rescue LoadError
  puts "   ❌ ruby-vips não encontrada"
  puts "      💡 Execute: bundle install"
  vips_available = false
end

# Teste 3: Verificar se a classe está carregável
puts "\n3️⃣ Verificando classe StickerImageOptimizerService..."
begin
  # Simular ambiente Rails mínimo
  unless defined?(Rails)
    class Rails
      def self.logger
        Logger.new(STDOUT)
      end
    end
  end
  
  unless defined?(ActiveModel)
    module ActiveModel
      module Model
        def self.included(base); end
      end
      module Attributes
        def self.included(base); end
      end
    end
  end
  
  unless defined?(StickerPerformanceMetricsService)
    class StickerPerformanceMetricsService
      def self.instance
        new
      end
      
      def track_api_performance(api_name:, response_time:, success:)
        # Mock implementation
      end
    end
  end
  
  # Carregar a classe
  require_relative 'app/services/sticker_image_optimizer_service'
  puts "   ✅ Classe carregada com sucesso"
  class_available = true
rescue StandardError => e
  puts "   ❌ Erro ao carregar classe: #{e.message}"
  class_available = false
end

# Resumo
puts "\n📋 RESUMO DA VALIDAÇÃO"
puts "=" * 30
puts "🔧 Ferramentas WebP: #{tools_available ? '✅' : '❌'}"
puts "💎 ruby-vips: #{vips_available ? '✅' : '❌'}"
puts "🧩 Classe Ruby: #{class_available ? '✅' : '❌'}"

ready = tools_available && vips_available && class_available
puts "\n🚀 Sistema pronto: #{ready ? '✅' : '❌'}"

unless ready
  puts "\n📝 PRÓXIMOS PASSOS:"
  puts "   1. Rebuild do Docker: docker-compose build" unless tools_available
  puts "   2. Bundle install: bundle install" unless vips_available
  puts "   3. Verificar dependências da classe" unless class_available
end

puts "\n✨ Validação concluída!"
