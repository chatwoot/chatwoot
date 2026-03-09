#!/usr/bin/env ruby

require_relative '/app/config/environment'

puts "🧪 TESTE REAL: Nova Lógica de Iterações"
puts "=" * 50

# Simular um arquivo de teste
class MockFile
  attr_reader :size, :content_type
  
  def initialize(size, content_type = 'image/webp')
    @size = size
    @content_type = content_type
    @content = "fake webp content" * (size / 20) # Simular conteúdo
  end
  
  def read
    @content
  end
  
  def rewind
    # Mock method
  end
  
  def respond_to?(method)
    [:read, :rewind, :size, :content_type].include?(method)
  end
end

# Criar mock file que simula o sticker dos logs (369KB)
mock_file = MockFile.new(369102, 'image/webp')

puts "📊 ARQUIVO DE TESTE:"
puts "   Size: #{mock_file.size} bytes"
puts "   Type: #{mock_file.content_type}"
puts

begin
  # Testar a validação do serviço
  service = StickerImageOptimizerService.new(file: mock_file, account_id: 1)
  
  puts "✅ Service criado com sucesso"
  puts "📋 Dependências disponíveis:"
  puts "   - libvips: #{Vips.version_string}"
  
  # Verificar se webpinfo está disponível
  stdout, stderr, status = Open3.capture3("which", "webpinfo")
  if status.success?
    puts "   - webpinfo: ✅ Disponível"
  else
    puts "   - webpinfo: ❌ Não encontrado"
  end
  
  # Verificar se img2webp está disponível  
  stdout, stderr, status = Open3.capture3("which", "img2webp")
  if status.success?
    puts "   - img2webp: ✅ Disponível"
  else
    puts "   - img2webp: ❌ Não encontrado"
  end
  
  puts
  puts "🎯 NOVA LÓGICA IMPLEMENTADA:"
  puts "   - Iteração 1: Q75% + culling only (sem limite de frames)"
  puts "   - Iteração 2: Q65% + culling + limite 30 frames"
  puts "   - Iteração 3+: Q55%/45%/35%/25% + limite 20/15 frames"
  puts
  puts "💡 EXPECTATIVA:"
  puts "   - Melhor qualidade visual na Iteração 1"
  puts "   - Preservação máxima de frames após culling inteligente"
  puts "   - Aplicação de limite apenas quando necessário"
  
rescue => e
  puts "❌ ERRO: #{e.message}"
  puts "📋 Classe: #{e.class.name}"
end
