#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🔍 DEBUG: Verificando aplicação de delays"
puts "=" * 60

# Usar o arquivo love.webp diretamente
input_file = "/app/app/uploaders/love.webp"
temp_output = "/tmp/debug_delays.webp"

puts "📁 Testando com: #{input_file}"

begin
  # Otimizar usando nosso serviço
  file_io = File.open(input_file, 'rb')
  optimizer = StickerImageOptimizerService.new(file: file_io, account_id: 1)
  
  # Interceptar antes do processo
  puts "🔧 Chamando otimização..."
  result = optimizer.process
  
  if result[:success]
    # Salvar arquivo temporariamente
    temp_file = result[:processed_file].tempfile
    FileUtils.cp(temp_file.path, temp_output)
    
    puts "✅ Otimização bem-sucedida"
    puts "📊 Arquivo salvo em: #{temp_output}"
    
    # Verificar metadados do arquivo resultante
    puts "\n🔍 VERIFICANDO METADADOS DO ARQUIVO RESULTANTE:"
    
    begin
      # Usar webpinfo para verificar delays
      stdout, stderr, status = Open3.capture3("webpinfo", "-summary", temp_output)
      
      if status.success?
        puts "📋 webpinfo output:"
        puts stdout
        
        # Extrair informações de delay se presentes
        if stdout.include?("Duration:")
          duration_lines = stdout.lines.select { |line| line.include?("Duration:") }
          puts "\n⏱️ DELAYS ENCONTRADOS:"
          duration_lines.each { |line| puts "  #{line.strip}" }
        else
          puts "⚠️ Nenhuma informação de duration encontrada"
        end
      else
        puts "❌ webpinfo falhou: #{stderr}"
      end
      
    rescue => e
      puts "❌ Erro ao verificar metadados: #{e.message}"
    end
    
    # Verificar usando libvips também
    begin
      puts "\n🔍 VERIFICANDO COM LIBVIPS:"
      vips_image = Vips::Image.new_from_file(temp_output, n: -1)
      
      begin
        delays = vips_image.get('delay')
        puts "⏱️ Delays libvips: #{delays.inspect}"
        puts "🕐 Duração total: #{delays.sum}ms"
      rescue
        puts "⚠️ Não foi possível obter delays via libvips"
      end
      
      begin
        n_pages = vips_image.get('n-pages')
        puts "🎞️ Número de frames: #{n_pages}"
      rescue
        puts "⚠️ Não foi possível obter n-pages"
      end
      
    rescue => e
      puts "❌ Erro ao verificar com libvips: #{e.message}"
    end
    
  else
    puts "❌ Otimização falhou: #{result[:error]}"
  end
  
rescue => e
  puts "❌ Erro geral: #{e.class.name}: #{e.message}"
  puts "📋 Backtrace:"
  e.backtrace.first(5).each { |line| puts "  #{line}" }
ensure
  file_io&.close
end

puts "\n🏁 Debug finalizado!"
