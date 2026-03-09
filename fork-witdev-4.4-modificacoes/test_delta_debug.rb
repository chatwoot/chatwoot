#!/usr/bin/env ruby
# frozen_string_literal: true

# TESTE SIMPLES DELTA-AWARE - DEBUG
puts "=== TESTE SIMPLES DELTA-AWARE DEBUG ==="

# Setup básico
class TestFile
  attr_accessor :content_type, :size, :tempfile
  
  def initialize(path)
    @tempfile = File.open(path)
    @content_type = 'image/webp'
    @size = File.size(path)
  end
  
  def read
    @tempfile.read
  end
  
  def rewind
    @tempfile.rewind
  end
end

# Arquivo de teste
test_file_path = '/tmp/love.webp'
puts "📁 Testando arquivo: #{test_file_path}"
puts "📊 Tamanho: #{File.size(test_file_path)} bytes"

# Testar apenas metadados primeiro
puts "\n=== TESTE 1: Metadados Básicos ==="
begin
  service = StickerImageOptimizerService.new(file: TestFile.new(test_file_path))
  
  puts "✅ Serviço inicializado"
  
  # Testar extração de metadados
  metadata = service.send(:extract_metadata_with_webpinfo, test_file_path)
  puts "✅ Metadados extraídos:"
  puts "  Frames: #{metadata[:frame_count]}"
  puts "  Durações: #{metadata[:durations]&.length || 0} entradas"
  
  if metadata[:frame_count] > 1
    puts "✅ Arquivo é animado - #{metadata[:frame_count]} frames"
    
    # Testar estratégia
    strategy = service.send(:determine_optimization_strategy, metadata[:frame_count])
    puts "✅ Estratégia determinada: #{strategy[:name]}"
    puts "  Qualidade: #{strategy[:quality]}"
    puts "  Frame culling: #{strategy[:enable_frame_culling]}"
  else
    puts "ℹ️ Arquivo é estático - não precisa Delta-Aware"
  end
  
rescue => e
  puts "❌ Erro no teste básico:"
  puts "  #{e.message}"
  puts "  #{e.class.name}"
end

puts "\n=== TESTE 2: Processamento Simplificado ==="
begin
  # Testar apenas o método básico sem Delta-Aware
  service = StickerImageOptimizerService.new(file: TestFile.new(test_file_path))
  
  puts "🔄 Iniciando processamento básico..."
  puts "📝 Log 1: Serviço inicializado"
  start_time = Time.current
  
  # Usar método mais simples
  puts "📝 Log 2: Criando arquivos temporários..."
  temp_input = Tempfile.new(['test_input', '.webp'], binmode: true)
  temp_output = Tempfile.new(['test_output', '.webp'], binmode: true)
  
  puts "📝 Log 3: Arquivos temporários criados"
  puts "  Input: #{temp_input.path}"
  puts "  Output: #{temp_output.path}"
  
  # Copiar arquivo
  puts "📝 Log 4: Copiando arquivo de teste..."
  File.open(test_file_path, 'rb') do |source|
    temp_input.binmode
    temp_input.write(source.read)
    temp_input.flush
  end
  
  puts "📝 Log 5: Arquivo copiado (#{File.size(temp_input.path)} bytes)"
  
  # Testar validação de dependências primeiro
  puts "📝 Log 6: Validando dependências do sistema..."
  service.send(:validate_system_dependencies!)
  puts "📝 Log 7: Dependências validadas ✅"
  
  # Testar extração de metadados
  puts "📝 Log 8: Extraindo metadados..."
  metadata = service.send(:extract_metadata_with_webpinfo, temp_input.path)
  puts "📝 Log 9: Metadados extraídos - #{metadata[:frame_count]} frames"
  
  # Verificar se é animado
  if metadata[:frame_count] > 1
    puts "📝 Log 10: Arquivo animado detectado - processamento completo"
    
    # Testar estratégia
    puts "📝 Log 11: Determinando estratégia..."
    strategy = service.send(:determine_optimization_strategy, metadata[:frame_count])
    puts "📝 Log 12: Estratégia determinada: #{strategy[:name]}"
    
    # Verificar se vai usar Delta-Aware
    if strategy[:enable_frame_culling]
      puts "📝 Log 13: ⚠️ ESTRATÉGIA DELTA-AWARE DETECTADA - pode ser lenta"
      puts "📝 Log 14: Frame culling ativo com threshold #{strategy[:cull_threshold]}"
    else
      puts "📝 Log 13: Estratégia convencional (sem frame culling)"
    end
    
  else
    puts "📝 Log 10: Arquivo estático - processamento simples"
  end
  
  # Testar apenas o método básico libvips
  puts "📝 Log 15: INICIANDO create_sticker_with_libvips_architecture..."
  puts "📝 Log 16: Parâmetros - input: #{temp_input.path}, output: #{temp_output.path}"
  
  output_path = service.send(:create_sticker_with_libvips_architecture, temp_input.path, temp_output.path)
  
  processing_time = ((Time.current - start_time) * 1000).round(2)
  
  puts "📝 Log 17: ✅ Processamento básico concluído em #{processing_time}ms"
  puts "📊 Arquivo resultado: #{File.size(output_path)} bytes"
  
  # Cleanup
  puts "📝 Log 18: Limpando arquivos temporários..."
  temp_input.close!
  temp_output.close!
  puts "📝 Log 19: Cleanup concluído"
  
rescue => e
  puts "❌ Erro no processamento básico:"
  puts "  #{e.message}"
  puts "  #{e.class.name}"
  puts "  Backtrace:"
  e.backtrace.first(5).each { |line| puts "    #{line}" }
end

puts "\n=== CONCLUSÃO DEBUG ==="
puts "Teste de debug concluído."
