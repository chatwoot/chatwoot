#!/usr/bin/env ruby
# frozen_string_literal: true

# Script de teste para validar a implementação libvips conforme guia técnico
# Execute: ruby test_libvips_implementation.rb

require_relative '../config/environment'

class LibvipsImplementationTester
  def self.test_all
    puts "\n🔍 TESTE DE IMPLEMENTAÇÃO LIBVIPS CONFORME GUIA TÉCNICO"
    puts "=" * 60

    # Teste 1: Verificar dependências do sistema
    test_system_dependencies

    # Teste 2: Verificar se a gem ruby-vips está disponível
    test_ruby_vips_availability

    # Teste 3: Testar arquivos de exemplo (se disponíveis)
    test_sample_files

    # Teste 4: Benchmark comparativo (se tiver arquivos)
    test_benchmark_comparison

    puts "\n✅ TESTES CONCLUÍDOS"
  end

  def self.test_system_dependencies
    puts "\n1️⃣ Testando dependências do sistema..."
    
    required_tools = %w[webpinfo webpmux img2webp]
    
    required_tools.each do |tool|
      stdout, stderr, status = Open3.capture3("which", tool)
      if status.success?
        puts "   ✅ #{tool}: #{stdout.strip}"
      else
        puts "   ❌ #{tool}: NÃO ENCONTRADO"
        puts "      💡 Instale com: apt-get install webp (Debian/Ubuntu)"
      end
    end
  end

  def self.test_ruby_vips_availability
    puts "\n2️⃣ Testando disponibilidade do ruby-vips..."
    
    begin
      require 'vips'
      version = Vips.version_string
      puts "   ✅ ruby-vips disponível: #{version}"
      
      # Testar operação básica
      test_image = Vips::Image.black(100, 100)
      puts "   ✅ Operação básica libvips: OK"
      
    rescue LoadError
      puts "   ❌ ruby-vips NÃO DISPONÍVEL"
      puts "      💡 Instale com:"
      puts "         Gemfile: gem 'ruby-vips'"
      puts "         Sistema: apt-get install libvips-dev"
      return false
    rescue StandardError => e
      puts "   ❌ Erro ao testar libvips: #{e.message}"
      return false
    end
    
    true
  end

  def self.test_sample_files
    puts "\n3️⃣ Procurando arquivos de teste..."
    
    # Procurar por arquivos WebP de exemplo no projeto
    webp_files = Dir.glob("**/*.webp").first(3)
    
    if webp_files.empty?
      puts "   ⚠️  Nenhum arquivo WebP encontrado para teste"
      puts "      💡 Para testar completamente, adicione arquivos .webp de exemplo"
      return
    end
    
    webp_files.each do |file|
      puts "\n   📁 Testando arquivo: #{file}"
      test_webp_file(file)
    end
  end

  def self.test_webp_file(file_path)
    begin
      # Testar webpinfo
      stdout, stderr, status = Open3.capture3("webpinfo", file_path)
      if status.success?
        frame_count = stdout.match(/Number of frames:\s+(\d+)/)&.captures&.first&.to_i || 1
        puts "      ✅ webpinfo: #{frame_count} frames detectados"
      else
        puts "      ❌ webpinfo falhou: #{stderr}"
        return
      end
      
      # Testar carregamento com libvips
      if defined?(Vips)
        image = Vips::Image.new_from_file(file_path, n: 1) # Primeiro frame apenas
        puts "      ✅ libvips load: #{image.width}x#{image.height}"
        
        # Testar se tem múltiplos frames
        if frame_count > 1
          full_image = Vips::Image.new_from_file(file_path, n: -1)
          puts "      ✅ libvips animation: #{full_image.height / image.height} frames calculados"
        end
      end
      
    rescue StandardError => e
      puts "      ❌ Erro: #{e.message}"
    end
  end

  def self.test_benchmark_comparison
    puts "\n4️⃣ Preparando benchmark comparativo..."
    
    # Procurar um arquivo adequado para benchmark
    webp_files = Dir.glob("**/*.webp")
    suitable_file = webp_files.find { |f| File.size(f) > 10.kilobytes && File.size(f) < 1.megabyte }
    
    unless suitable_file
      puts "   ⚠️  Nenhum arquivo adequado para benchmark encontrado"
      puts "      💡 Para benchmark, adicione um arquivo WebP de 10KB-1MB"
      return
    end
    
    puts "   📊 Arquivo para benchmark: #{suitable_file} (#{File.size(suitable_file)} bytes)"
    
    # Simular arquivo upload para teste
    file_mock = OpenStruct.new(
      read: File.read(suitable_file),
      rewind: -> {},
      size: File.size(suitable_file),
      content_type: 'image/webp'
    )
    
    begin
      # Testar apenas se as classes existem
      if defined?(StickerImageOptimizerService) && defined?(StickerLibvipsOptimizerService)
        puts "   ✅ Classes de processamento disponíveis"
        puts "   💡 Execute StickerLibvipsOptimizerService.benchmark_comparison(file) para comparar"
      else
        puts "   ⚠️  Classes de processamento não carregadas completamente"
      end
      
    rescue StandardError => e
      puts "   ❌ Erro no benchmark: #{e.message}"
    end
  end

  def self.create_test_report
    puts "\n📋 RELATÓRIO DE PREPARAÇÃO PARA MIGRAÇÃO"
    puts "=" * 50
    
    report = {
      webp_tools: system_has_webp_tools?,
      ruby_vips: ruby_vips_available?,
      sample_files: Dir.glob("**/*.webp").count,
      ready_for_testing: false
    }
    
    report[:ready_for_testing] = report[:webp_tools] && report[:ruby_vips]
    
    puts "🔧 Ferramentas WebP: #{report[:webp_tools] ? '✅' : '❌'}"
    puts "💎 ruby-vips: #{report[:ruby_vips] ? '✅' : '❌'}"
    puts "📁 Arquivos de teste: #{report[:sample_files]} arquivos .webp"
    puts "🚀 Pronto para testes: #{report[:ready_for_testing] ? '✅' : '❌'}"
    
    unless report[:ready_for_testing]
      puts "\n📝 AÇÕES NECESSÁRIAS:"
      puts "   1. Instalar ferramentas WebP: apt-get install webp" unless report[:webp_tools]
      puts "   2. Instalar libvips: apt-get install libvips-dev && bundle install" unless report[:ruby_vips]
      puts "   3. Adicionar arquivos .webp de teste para validação completa"
    end
    
    report
  end

  private

  def self.system_has_webp_tools?
    %w[webpinfo webpmux img2webp].all? do |tool|
      system("which #{tool} > /dev/null 2>&1")
    end
  end

  def self.ruby_vips_available?
    require 'vips'
    Vips.version
    true
  rescue LoadError
    false
  end
end

# Executar testes se chamado diretamente
if __FILE__ == $0
  begin
    LibvipsImplementationTester.test_all
    LibvipsImplementationTester.create_test_report
  rescue StandardError => e
    puts "\n❌ ERRO NO TESTE: #{e.message}"
    puts e.backtrace.join("\n")
  end
end
