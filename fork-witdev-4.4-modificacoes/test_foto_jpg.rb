#!/usr/bin/env ruby
require_relative 'config/environment'
require 'tempfile'

puts "🧪 Testando foto.jpg específica"
puts "=" * 50

foto_path = 'app/uploaders/foto.jpg'

if File.exist?(foto_path)
  puts "📁 Arquivo encontrado: #{foto_path}"
  
  # Verificar tamanho original
  original_size = File.size(foto_path)
  puts "📊 Tamanho original: #{original_size} bytes (#{(original_size / 1024.0).round(2)} KB)"
  
  # Verificar se precisa de otimização (>100KB para estática)
  max_static_size = 100 * 1024 # 100KB
  needs_optimization = original_size > max_static_size
  puts "🔍 Precisa otimização: #{needs_optimization ? 'SIM' : 'NÃO'} (limite: 100KB)"
  
  begin
    # Testar com o StickerImageOptimizerService
    puts "\n🔧 Testando StickerImageOptimizerService..."
    
    # Criar um mock de arquivo uploaded
    file_data = File.read(foto_path)
    uploaded_file = ActionDispatch::Http::UploadedFile.new(
      tempfile: Tempfile.new(['foto', '.jpg']).tap { |f| f.write(file_data); f.rewind },
      filename: 'foto.jpg',
      type: 'image/jpeg'
    )
    
    optimizer = StickerImageOptimizerService.new(
      file: uploaded_file,
      account_id: 3
    )
    
    puts "🚀 Executando otimização..."
    
    # Adicionar debug para capturar o erro específico
    result = optimizer.process
    
    if result[:success]
      Rails.logger.info "[TEST] ✅ Resultado de sucesso: #{result.keys}"
      
      if result[:optimized_data]
        optimized_size = result[:optimized_data].bytesize
        reduction_percent = ((original_size - optimized_size) / original_size.to_f * 100).round(2)
        
        puts "✅ Otimização bem-sucedida!"
        puts "📊 Tamanho otimizado: #{optimized_size} bytes (#{(optimized_size / 1024.0).round(2)} KB)"
        puts "📈 Redução: #{reduction_percent}%"
        puts "🎯 Dentro do limite 100KB: #{optimized_size <= max_static_size ? 'SIM ✅' : 'NÃO ❌'}"
        
        # Salvar resultado para inspeção
        output_path = 'app/uploaders/foto_otimizada.webp'
        File.write(output_path, result[:optimized_data])
        puts "💾 Resultado salvo em: #{output_path}"
      elsif result[:processed_file]
        puts "✅ Otimização bem-sucedida!"
        puts "📁 Arquivo processado: #{result[:processed_file]}"
        puts "📊 Tamanho original: #{result[:original_size]} bytes"
        puts "📊 Tamanho final: #{result[:final_size]} bytes"
        
        if result[:final_size]
          reduction_percent = ((result[:original_size] - result[:final_size]) / result[:original_size].to_f * 100).round(2)
          puts "📈 Redução: #{reduction_percent}%"
          puts "🎯 Dentro do limite 100KB: #{result[:final_size] <= max_static_size ? 'SIM ✅' : 'NÃO ❌'}"
        end
      else
        puts "⚠️ Sucesso mas sem dados de otimização. Resultado: #{result}"
      end
      
    else
      puts "❌ Erro na otimização: #{result[:error] || result[:message]}"
      puts "🔍 Verifique os logs do Rails para backtrace completo!"
      puts "💡 Executar: docker logs chatwit-rails-1 --tail 50"
    end
    
  rescue => e
    puts "💥 Exceção durante teste: #{e.message}"
    puts "🔍 Backtrace:"
    puts e.backtrace.first(5).join("\n")
  end
  
else
  puts "❌ Arquivo não encontrado: #{foto_path}"
  puts "📁 Conteúdo do diretório app/uploaders/:"
  Dir.glob('app/uploaders/*').each do |file|
    puts "  - #{file}"
  end
end

puts "\n" + "=" * 50
puts "🏁 Teste finalizado"
