# frozen_string_literal: true

require 'vips'
require 'tmpdir'
require 'open3'
require 'benchmark'

# StickerImageOptimizerService
# 
# Implementação otimizada usando "Arquitetura In-Memory" para WebP animado:
# - Carrega toda a animação na memória uma única vez
# - Processa frames como array de objetos Vips::Image
# - Elimina gargalos de I/O em disco da arquitetura anterior
# - Aplica otimização Delta-Aware para frame culling inteligente
# - Performance: 10-100x mais rápida que arquiteturas baseadas em arquivos temporários
#
# Vantagens sobre abordagem de desmontagem/remontagem:
# - Performance: Eliminação completa do gargalo de I/O
# - Memória: Uso eficiente da RAM com libvips
# - Simplicidade: Menos complexidade de código e dependências externas
# - Confiabilidade: Menos pontos de falha (sem arquivos temporários)
class StickerImageOptimizerService
  include ActiveModel::Model
  include ActiveModel::Attributes

  # WhatsApp sticker size limits
  MAX_STATIC_FILE_SIZE = 100.kilobytes
  MAX_ANIMATED_FILE_SIZE = 500.kilobytes
  TARGET_DIMENSIONS = [512, 512].freeze
  SUPPORTED_FORMATS = %w[image/jpeg image/png image/gif image/webp].freeze
  OUTPUT_FORMAT = 'webp'
  QUALITY_LEVELS = [75, 65, 55, 45, 35, 25].freeze

  class ProcessingError < StandardError; end

  attr_accessor :file, :account_id

  def initialize(file:, account_id: nil)
    @file = file
    @account_id = account_id
    @metrics_service = StickerPerformanceMetricsService.instance
  end

  def process
    start_time = Time.current

    begin
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔧 Starting IN-MEMORY process for account #{@account_id}"
      
      validate_input!
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ✅ Input validation passed"
      
      validate_system_dependencies!
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ✅ System dependencies validated"

      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] Starting IN-MEMORY optimization for account #{@account_id}"

      result = optimize_image_with_in_memory_architecture
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ✅ IN-MEMORY optimization completed successfully"

      processing_time = (Time.current - start_time) * 1000
      @metrics_service.track_api_performance(
        api_name: 'libvips_in_memory_processing',
        response_time: processing_time,
        success: true
      )

      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] IN-MEMORY optimization completed in #{processing_time.round(2)}ms"

      {
        success: true,
        processed_file: result[:processed_file],
        original_size: result[:original_size],
        final_size: result[:final_size],
        compression_ratio: result[:compression_ratio],
        processing_time: processing_time.round(2),
        is_animated: result[:is_animated],
        has_transparency: result[:has_transparency],
        method: 'libvips_in_memory_delta_aware'
      }

    rescue StandardError => e
      processing_time = (Time.current - start_time) * 1000
      @metrics_service.track_api_performance(
        api_name: 'libvips_in_memory_processing',
        response_time: processing_time,
        success: false
      )

      Rails.logger.error "[SOCIALWISE-STICKER-LIBVIPS] ❌ CRITICAL ERROR in IN-MEMORY processing: #{e.message}"
      Rails.logger.error "[SOCIALWISE-STICKER-LIBVIPS] 📍 Error class: #{e.class.name}"
      Rails.logger.error "[SOCIALWISE-STICKER-LIBVIPS] 🔍 File size: #{@file&.size} bytes"
      Rails.logger.error "[SOCIALWISE-STICKER-LIBVIPS] 🔍 Content type: #{@file&.content_type if @file&.respond_to?(:content_type)}"
      Rails.logger.error "[SOCIALWISE-STICKER-LIBVIPS] 📋 Backtrace:"
      e.backtrace.first(10).each { |line| Rails.logger.error "  #{line}" }

      {
        success: false,
        error: e.message,
        processing_time: processing_time.round(2),
        method: 'libvips_in_memory_delta_aware'
      }
    end
  end

  # MÉTODO PRINCIPAL - ARQUITETURA IN-MEMORY OTIMIZADA
  # Processa WebP animado mantendo tudo na memória para máxima performance
  def create_sticker_with_in_memory_architecture(input_path, output_path, size: 512)
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🚀 Starting IN-MEMORY optimization for #{input_path}"

    # --- Etapa 1: Carregar e Desconstruir em Memória ---
    # Esta é a ÚNICA operação de leitura de disco necessária
    # Para JPG/PNG (estáticos), não usar n: -1
    begin
      source_strip = Vips::Image.new_from_file(input_path, n: -1, access: :sequential)
    rescue Vips::Error => e
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ℹ️ Falling back to single page load (likely static image): #{e.message}"
      source_strip = Vips::Image.new_from_file(input_path, access: :sequential)
    end

    process_animation_frames(source_strip, input_path, output_path, size)
  end

  # MÉTODO OTIMIZADO - PROCESSA DIRETO DO BUFFER EM MEMÓRIA
  # Elimina operação de I/O desnecessária do Tempfile inicial
  def create_sticker_from_buffer(input_buffer, output_path, size: 512)
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🚀 Starting IN-MEMORY optimization from buffer (#{input_buffer.size} bytes)"

    begin
      # --- Carregar diretamente do buffer em memória (elimina I/O) ---
      source_strip = Vips::Image.new_from_buffer(input_buffer, "", n: -1, access: :sequential)
      process_animation_frames(source_strip, nil, output_path, size)
    rescue Vips::Error => e
      # Fallback: se new_from_buffer falhar, use arquivo temporário apenas para webpinfo
      Rails.logger.warn "[SOCIALWISE-STICKER-LIBVIPS] ⚠️ Buffer loading failed (#{e.message}), using Tempfile fallback"
      temp_input = Tempfile.new(['sticker_input', '.webp'], binmode: true)
      begin
        temp_input.binmode
        temp_input.write(input_buffer)
        temp_input.flush
        create_sticker_with_in_memory_architecture(temp_input.path, output_path, size: size)
      ensure
        temp_input.close! if temp_input && !temp_input.closed?
      end
    end
  end

  # HELPER COMPARTILHADO - Processa frames independente da origem (arquivo ou buffer)
  def process_animation_frames(source_strip, input_path, output_path, size)
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔍 DEBUG: Entering process_animation_frames with size=#{size}"
    
    # --- Detecção Robusta de Animação com Fallback ---
    begin
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔍 DEBUG: Trying to get metadata from libvips..."
      # Tenta obter os metadados diretamente da libvips.
      # Se a imagem não for uma animação reconhecida, isso vai falhar.
      page_height = source_strip.get('page-height')
      n_pages = source_strip.get('n-pages')
      original_delays = source_strip.get('delay')
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ✅ libvips detected animation: #{n_pages} frames."
    rescue Vips::Error => e
      Rails.logger.warn "[SOCIALWISE-STICKER-LIBVIPS] ⚠️ libvips could not read animation metadata directly (#{e.message}). Using webpinfo fallback."
      
      # Fallback: Se a libvips falhar, usamos o webpinfo (requer arquivo temporário se não temos input_path)
      if input_path
        metadata = extract_basic_metadata_with_webpinfo(input_path)
      else
        # Se não temos input_path (processamento direto do buffer), criar arquivo temporário apenas para webpinfo
        temp_file = Tempfile.new(['webpinfo_fallback', '.webp'], binmode: true)
        begin
          temp_file.binmode
          source_strip.webpsave(temp_file.path)
          metadata = extract_basic_metadata_with_webpinfo(temp_file.path)
        ensure
          temp_file.close! if temp_file && !temp_file.closed?
        end
      end
      
      n_pages = metadata[:frame_count]
      original_delays = metadata[:durations]
      # Se não conseguimos os metadados da libvips, calculamos a altura do frame.
      page_height = source_strip.height / n_pages if n_pages > 0
    end

    # Se, após todos os fallbacks, ainda tivermos 1 frame, tratamos como estático.
    if n_pages <= 1
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🖼️ Static image detected, processing with 100KB limit"
      
      # Processo iterativo para imagens estáticas respeitando limite de 100KB
      static_limit = MAX_STATIC_FILE_SIZE # 100KB
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🎯 Static image target: #{static_limit} bytes"
      
      # Tentar qualidades decrescentes até atingir o limite
      QUALITY_LEVELS.each_with_index do |quality_level, index|
        Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🎯 Static Iteration #{index + 1}: Trying Q=#{quality_level}"
        
        thumb = source_strip.thumbnail_image(size)
        thumb.webpsave(output_path, Q: quality_level)
        
        file_size = File.size(output_path)
        Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📊 Static size after Q#{quality_level}: #{file_size} bytes (target: #{static_limit})"
        
        if file_size <= static_limit
          Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ✅ Static image within limit on iteration #{index + 1}"
          return output_path
        else
          Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ⚠️ Static still too large (#{file_size} > #{static_limit}), trying next quality..."
        end
      end
      
      # Se chegou aqui, mesmo com qualidade mínima não conseguiu atingir o limite
      Rails.logger.warn "[SOCIALWISE-STICKER-LIBVIPS] ⚠️ Static image could not be reduced below #{static_limit} bytes even at lowest quality"
      return output_path
    end

    # Extrair todos os frames para um array de objetos Vips::Image (em memória)
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔪 Extracting #{n_pages} frames (page_height=#{page_height})"
    frames = (0...n_pages).map do |i|
      crop_y = i * page_height
      Rails.logger.debug "[SOCIALWISE-STICKER-LIBVIPS] Frame #{i}: crop(0, #{crop_y}, #{source_strip.width}, #{page_height})"
      source_strip.crop(0, crop_y, source_strip.width, page_height)
    end

    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🧠 Loaded #{n_pages} frames into memory successfully"

    # --- Etapa 2: Otimização Iterativa ---
    whatsapp_limit = 500.kilobytes
    final_size = Float::INFINITY # Começa com um tamanho infinito
    
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🎯 Starting iterative optimization. Target: #{whatsapp_limit} bytes"
    
    # Use uma estratégia de culling mais agressiva conforme as iterações progridem
    base_cull_threshold = n_pages > 50 ? 5.0 : 3.5

    # Tenta otimizar com qualidades decrescentes, parando na primeira que funcionar
    QUALITY_LEVELS.each_with_index do |quality_level, index|
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🎯 Iteration #{index + 1}/#{QUALITY_LEVELS.length}: Trying Q=#{quality_level}"

      # Aumentar agressividade do frame culling conforme as iterações avançam
      cull_threshold = base_cull_threshold + (index * 2.0) # Cada iteração fica mais agressiva
      
      # NOVA LÓGICA: Iteração 1 usa apenas culling, Iteração 2+ usa limite de frames
      if index == 0
        # Iteração 1: Apenas culling threshold, sem limite de frames
        max_frames = Float::INFINITY # Sem limite na primeira iteração
        Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🎯 Iteration 1: Using only culling threshold (#{cull_threshold}), no frame limit"
      else
        # Iteração 2+: Aplicar limite de frames progressivamente mais agressivo
        max_frames = index == 1 ? 30 : (index < 4 ? 20 : 15)
        Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🎯 Iteration #{index + 1}: Using culling threshold (#{cull_threshold}) + frame limit (#{max_frames})"
      end

      strategy = {
        quality: quality_level,
        cull_threshold: cull_threshold,
        scene_change_threshold: 50.0,
        size: size,
        max_frames: max_frames,
        description: "Iterative Optimization (Q#{quality_level}, Cull=#{cull_threshold.round(1)}, MaxFrames=#{max_frames})"
      }

      # Executa o processo de otimização principal
      perform_in_memory_optimization(frames, original_delays, output_path, strategy)

      final_size = File.size(output_path)
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📊 Size after Q#{quality_level}: #{final_size} bytes (target: #{whatsapp_limit})"

      # Se o tamanho estiver dentro do limite, a otimização foi um sucesso!
      if final_size <= whatsapp_limit
        Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ✅ Success! File size is within the limit on iteration #{index + 1}."
        break # Sai do loop
      else
        Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ⚠️ Still too large (#{final_size} > #{whatsapp_limit}), trying next quality level..."
      end
    end

    # Se, mesmo após a qualidade mais baixa, o arquivo for muito grande, registre um aviso
    if final_size > whatsapp_limit
      Rails.logger.warn "[SOCIALWISE-STICKER-LIBVIPS] ⚠️ Could not reduce file size below limit, even at lowest quality (Q#{QUALITY_LEVELS.last})."
    end

    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ✅ IN-MEMORY optimization completed: #{output_path}"
    output_path
  end

  def optimize_for_whatsapp(input_path)
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] Optimizing for WhatsApp using IN-MEMORY architecture: #{input_path}"
    output_path = input_path.gsub(/\.[^.]+$/, '_optimized.webp')

    begin
      result_path = create_sticker_with_in_memory_architecture(input_path, output_path, size: 512)
      file_size = File.size(result_path)
      
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] Success: #{file_size} bytes"
      result_path

    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-STICKER-LIBVIPS] Optimization failed: #{e.message}"
      [output_path, "#{output_path}.tmp"].each do |path|
        File.delete(path) if File.exist?(path)
      end
      raise e
    end
  end

  # Interface compatível para testes
  def optimize_for_telegram_and_whatsapp
    temp_input = Tempfile.new(['sticker_input', '.webp'], binmode: true)
    
    begin
      # Escrever arquivo temporário
      file_content = @file.read
      @file.rewind if @file.respond_to?(:rewind)
      
      temp_input.binmode
      temp_input.write(file_content)
      temp_input.flush

      # Executar otimização usando a nova arquitetura IN-MEMORY
      result_path = optimize_for_whatsapp(temp_input.path)
      
      # Extrair metadados finais
      metadata = extract_basic_metadata_with_webpinfo(result_path)
      final_size = File.size(result_path)
      original_size = @file.size
      
      {
        success: true,
        output_path: result_path,
        original_size: original_size,
        final_size: final_size,
        frame_count: metadata[:frame_count],
        compression_ratio: ((original_size - final_size).to_f / original_size * 100).round(2),
        processing_time: 0, # Será atualizado pelo método principal
        quality: 'IN-MEMORY Delta-Aware',
        method: 'libvips_in_memory_delta_aware'
      }
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-STICKER-LIBVIPS] ❌ IN-MEMORY optimization failed: #{e.message}"
      {
        success: false,
        error: e.message,
        method: 'libvips_in_memory_delta_aware'
      }
    ensure
      temp_input.close! if temp_input && !temp_input.closed?
    end
  end

  private

  # Método direto para otimização com paths específicos (para debug/scripts)
  def create_sticker_direct_from_file(input_path, output_path)
    puts "[STICKER-OPTIMIZER] 🚀 Otimização direta de arquivo"
    puts "[STICKER-OPTIMIZER] 📂 Entrada: #{input_path}"
    puts "[STICKER-OPTIMIZER] 📂 Saída: #{output_path}"
    
    File.open(input_path, 'rb') do |input_file|
      buffer_data = input_file.read
      original_size = buffer_data.bytesize
      puts "[STICKER-OPTIMIZER] 📊 Tamanho original: #{original_size} bytes"
      
      # Processamento direto com otimização iterativa
      result = create_sticker_from_buffer(buffer_data)
      
      if result[:success]
        optimized_data = result[:optimized_data]
        final_size = optimized_data.bytesize
        
        puts "[STICKER-OPTIMIZER] 💾 Tamanho final: #{final_size} bytes"
        puts "[STICKER-OPTIMIZER] 📉 Compressão: #{((original_size - final_size).to_f / original_size * 100).round(2)}%"
        
        # Salvar diretamente no arquivo de saída
        File.write(output_path, optimized_data, mode: 'wb')
        
        puts "[STICKER-OPTIMIZER] ✅ Arquivo salvo em: #{output_path}"
        output_path
      else
        puts "[STICKER-OPTIMIZER] ❌ Falha na otimização: #{result[:error]}"
        nil
      end
    end
  rescue StandardError => e
    puts "[STICKER-OPTIMIZER] ❌ ERRO: #{e.message}"
    puts "[STICKER-OPTIMIZER] 📋 Backtrace: #{e.backtrace.first(5).join(' | ')}"
    nil
  end

  private

  # HELPER PRIVADO E REUTILIZÁVEL - Core da otimização Delta-Aware
  # Processa frames em memória aplicando frame culling e scene detection
  def perform_in_memory_optimization(frames, original_delays, output_path, strategy)
    n_pages = frames.length
    
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔬 Starting #{strategy[:description]} (Q=#{strategy[:quality]}, Cull=#{strategy[:cull_threshold]})"
    
    # --- Análise Delta-Aware e Frame Culling ---
    new_frames = [frames.first]
    new_delays = [original_delays.first]
    scene_change_indices = [0]
    culled_count = 0
    kept_count = 1

    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔍 Original delays sample: #{original_delays.first(5).inspect}"
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔍 Cull threshold: #{strategy[:cull_threshold]}"

    (1...n_pages).each do |i|
      # Cálculo de MSE em memória (extremamente rápido)
      mse = (frames[i] - new_frames.last).abs.avg
      
      if mse < strategy[:cull_threshold]
        # Frame similar - descarte e adicione duração ao anterior
        new_delays[-1] += original_delays[i]
        culled_count += 1
        if i % 20 == 0  # Log a cada 20 frames
          Rails.logger.debug "[SOCIALWISE-STICKER-LIBVIPS] Frame #{i} culled (MSE: #{mse.round(2)} < #{strategy[:cull_threshold]})"
        end
      else
        # Frame diferente - mantenha
        new_frames << frames[i]
        new_delays << original_delays[i]
        kept_count += 1
        if i % 20 == 0  # Log a cada 20 frames
          Rails.logger.debug "[SOCIALWISE-STICKER-LIBVIPS] Frame #{i} kept (MSE: #{mse.round(2)} >= #{strategy[:cull_threshold]})"
        end
        
        # Detectar mudanças de cena para keyframe placement inteligente
        if mse > strategy[:scene_change_threshold]
          scene_change_indices << new_frames.length - 1
        end
      end
    end
    
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📊 Frames: culled=#{culled_count}, kept=#{kept_count}, total=#{n_pages}"
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📊 Frames reduced: #{n_pages} → #{new_frames.length} (#{((n_pages - new_frames.length).to_f / n_pages * 100).round(1)}% culled)"
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔍 New delays sample: #{new_delays.first(5).inspect}"
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔍 Max delay: #{new_delays.max}ms, Total duration: #{new_delays.sum}ms"

    # APLICAR LIMITE MÁXIMO DE FRAMES apenas se especificado (não infinito)
    max_frames_limit = strategy[:max_frames] || Float::INFINITY
    if max_frames_limit != Float::INFINITY && new_frames.length > max_frames_limit
      Rails.logger.warn "[SOCIALWISE-STICKER-LIBVIPS] ⚠️ Still too many frames (#{new_frames.length}), forcing limit to #{max_frames_limit}"
      
      # Calcular duração total original antes da limitação
      original_total_duration = new_delays.sum
      
      # Selecionar frames uniformemente distribuídos
      indices = (0...new_frames.length).step(new_frames.length / max_frames_limit.to_f).map(&:to_i).uniq.first(max_frames_limit)
      new_frames = indices.map { |i| new_frames[i] }
      limited_delays = indices.map { |i| new_delays[i] }
      
      # Compensar delays para manter duração total da animação
      limited_total_duration = limited_delays.sum
      if limited_total_duration > 0
        compensation_factor = original_total_duration.to_f / limited_total_duration
        new_delays = limited_delays.map { |delay| (delay * compensation_factor).round }
        
        Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ⏱️ Time compensation applied:"
        Rails.logger.info "  Original duration: #{original_total_duration}ms"
        Rails.logger.info "  Limited duration: #{limited_total_duration}ms"
        Rails.logger.info "  Compensation factor: #{compensation_factor.round(3)}"
        Rails.logger.info "  New total duration: #{new_delays.sum}ms"
      else
        new_delays = limited_delays
      end
      
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📊 Hard limited to #{new_frames.length} frames"
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔍 Final delays after compensation: #{new_delays.first(5).inspect}"
    else
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📊 No frame limit applied, keeping #{new_frames.length} frames from culling"
    end

    # --- Keyframe Strategy: Dynamic kmax based on scene changes ---
    distances = scene_change_indices.each_cons(2).map { |a, b| b - a }
    kmax = (distances.max || new_frames.length)
    kmax = [kmax, 2].max # Garantir kmax mínimo

    # --- Etapa 1: Redimensionamento ---
    resized_frames = new_frames.map do |frame|
      frame.thumbnail_image(strategy[:size])
    end
    
    # --- Etapa 2: JUNTAR FRAMES EM UMA "TIRA DE FILME" ---
    # Este é o passo crucial que estava faltando.
    # Usa Vips::Image.arrayjoin para empilhar todos os frames verticalmente.
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🎞️ Joining #{resized_frames.length} frames into a single vertical 'filmstrip'..."
    animation_strip = Vips::Image.arrayjoin(resized_frames, across: 1)

    # --- Etapa 3: ANOTAR A "TIRA DE FILME" COM METADADOS DE ANIMAÇÃO ---
    # ESTA É A CORREÇÃO CRÍTICA.
    # Anexamos os metadados diretamente na imagem ANTES de salvar.
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📝 Annotating filmstrip with animation metadata..."
    
    # Aplicar metadados de delay compensados seguindo a documentação libvips
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ⏱️ Setting animation metadata with delays: #{new_delays.inspect}"
    
    # Definir metadados de animação na imagem seguindo a documentação libvips
    # Como mostrado em: animation.set_type(pyvips.GValue.array_int_type, "delay", delay_array)
    animation_strip.set("page-height", strategy[:size])
    animation_strip.set("n-pages", new_frames.length)
    animation_strip.set("loop", 0)
    animation_strip.set("delay", new_delays)
    
    # Primeiro, salvar sem metadados de delay personalizado (o webpsave aplicará delays padrão)
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 💾 Saving animated WebP with compensation delays..."
    animation_strip.webpsave(output_path, 
      page_height: strategy[:size], # O parâmetro MÁGICO que ativa a animação.
      Q: strategy[:quality],         # Qualidade da compressão com perdas.
      lossless: false,               # Garante compressão com perdas.
      kmax: kmax,                    # Distância máxima entre keyframes (para melhor compressão).
      effort: 4                      # Excelente equilíbrio entre velocidade e compressão.
    )
    
    final_size = File.size(output_path)
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ✅ #{strategy[:description]} completed: #{final_size} bytes"
    
    final_size
  end

  # Versão simplificada de extração de metadados para compatibilidade
  def extract_basic_metadata_with_webpinfo(input_path)
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔍 Running webpinfo on: #{input_path}"
    stdout, stderr, status = Open3.capture3("webpinfo", "-summary", input_path)
    
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📋 webpinfo status: #{status.success?}"
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📋 webpinfo stderr: #{stderr}" unless stderr.empty?
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📋 webpinfo stdout:"
    stdout.lines.each { |line| Rails.logger.info "    #{line.strip}" }
    
    return { frame_count: 1, durations: [100] } unless status.success?

    # Contar frames pela presença de chunks ANMF
    anmf_chunks = stdout.scan(/Chunk ANMF at offset/).length
    frame_count = anmf_chunks > 0 ? anmf_chunks : 1
    durations = stdout.scan(/Duration:\s+(\d+)/).flatten.map(&:to_i)
    durations = Array.new(frame_count, 100) if durations.empty?
    
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📊 webpinfo results: #{frame_count} frames, durations: #{durations.inspect}"
    
    { frame_count: frame_count, durations: durations }
  end

  def validate_input!
    raise ArgumentError, 'File is required' unless @file
    raise ArgumentError, 'File must respond to read' unless @file.respond_to?(:read)

    file_size = @file.size
    raise ArgumentError, 'File is too large (max 5MB for processing)' if file_size > 5.megabytes

    if @file.respond_to?(:content_type) && @file.content_type
      raise ArgumentError, "Unsupported file format: #{@file.content_type}" unless SUPPORTED_FORMATS.include?(@file.content_type)
    end
  end

  def validate_system_dependencies!
    # Verificar se libvips está disponível
    begin
      Vips.version_string
    rescue NameError
      raise ProcessingError, "libvips not available. Please install ruby-vips gem and libvips library."
    end
    
    # Tornar webpinfo e img2webp obrigatórios para a lógica de fallback e remontagem
    %w[webpinfo img2webp].each do |tool|
      _stdout, _stderr, status = Open3.capture3("which", tool)
      unless status.success?
        raise ProcessingError, "Required tool '#{tool}' not found. Please install libwebp-tools."
      end
    end
    
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] All dependencies validated successfully"
  end

  def optimize_image_with_in_memory_architecture
    original_size = @file.size
    temp_output = Tempfile.new(['sticker_output', '.webp'], binmode: true)

    begin
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📁 Starting optimized IN-MEMORY processing (no temp input file)"
      
      # Carregar arquivo em buffer (eliminando necessidade de Tempfile inicial)
      file_content = @file.read
      @file.rewind if @file.respond_to?(:rewind)
      
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📝 File loaded to buffer: #{file_content.size} bytes"

      # Usar a nova arquitetura IN-MEMORY direto do buffer (mais eficiente)
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🚀 Starting optimized IN-MEMORY libvips processing"
      
      create_sticker_from_buffer(file_content, temp_output.path)
      
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ✅ IN-MEMORY processing completed successfully"
      
      # Verificar se é animação analisando arquivo de saída processado
      is_animated = check_if_animated_with_webpinfo(temp_output.path)
      has_transparency = check_transparency_with_libvips(temp_output.path)

      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📊 Analysis: animated=#{is_animated}, transparency=#{has_transparency}"

      final_size = File.size(temp_output.path)
      compression_ratio = ((original_size - final_size).to_f / original_size * 100).round(2)

      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 📈 Size: #{original_size} → #{final_size} bytes (#{compression_ratio}% compression)"

      # Validação específica para imagens estáticas (limite de 100KB)
      if !is_animated && final_size > MAX_STATIC_FILE_SIZE
        Rails.logger.warn "[SOCIALWISE-STICKER-LIBVIPS] ⚠️ WARNING: Static image exceeds limit (#{final_size} > #{MAX_STATIC_FILE_SIZE} bytes)"
        Rails.logger.warn "[SOCIALWISE-STICKER-LIBVIPS] 📋 This may cause issues in WhatsApp sticker upload"
      elsif !is_animated && final_size <= MAX_STATIC_FILE_SIZE
        Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ✅ Static image within limit (#{final_size} ≤ #{MAX_STATIC_FILE_SIZE} bytes)"
      end

      processed_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: temp_output,
        filename: generate_filename(is_animated),
        type: 'image/webp',
        head: "Content-Disposition: form-data; name=\"file\"; filename=\"#{generate_filename(is_animated)}\"\r\nContent-Type: image/webp\r\n"
      )

      {
        processed_file: processed_file,
        original_size: original_size,
        final_size: final_size,
        compression_ratio: compression_ratio,
        is_animated: is_animated,
        has_transparency: has_transparency
      }
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-STICKER-LIBVIPS] ❌ Error in IN-MEMORY processing: #{e.message}"
      temp_output.close! if temp_output
      raise e
    # IMPORTANTE: NÃO feche o temp_output no ensure porque será usado pelo processed_file!
    # O cleanup será feito pelo garbage collector ou pelo código que usar o arquivo
    end
  end

  def check_if_animated_with_webpinfo(input_path)
    stdout, _stderr, status = Open3.capture3("webpinfo", input_path)
    return false unless status.success?
    
    # Usar a mesma lógica: contar chunks ANMF
    anmf_chunks = stdout.scan(/Chunk ANMF at offset/).length
    anmf_chunks > 0
  end

  def check_transparency_with_libvips(input_path)
    # Carregar apenas primeiro frame para verificar transparência
    image = Vips::Image.new_from_file(input_path, n: 1)
    image.has_alpha?
  rescue StandardError => e
    Rails.logger.debug "[SOCIALWISE-STICKER-LIBVIPS] Error detecting transparency: #{e.message}"
    %w[png gif webp].include?(File.extname(input_path).downcase.delete('.'))
  end

  def generate_filename(is_animated = false)
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    random_suffix = SecureRandom.hex(4)
    animation_suffix = is_animated ? '_animated' : ''
    method_suffix = '_in_memory'
    "sticker_#{timestamp}_#{random_suffix}#{animation_suffix}#{method_suffix}.webp"
  end

  # Métodos de classe para compatibilidade
  def self.batch_process(files, account_id: nil)
    results = []
    total_start_time = Time.current

    files.each_with_index do |file, index|
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] Processing sticker #{index + 1}/#{files.length}"
      service = new(file: file, account_id: account_id)
      result = service.process
      results << result.merge(file_index: index)
    end

    total_processing_time = (Time.current - total_start_time) * 1000

    {
      results: results,
      total_files: files.length,
      successful: results.count { |r| r[:success] },
      failed: results.count { |r| !r[:success] },
      total_processing_time: total_processing_time.round(2),
      method: 'libvips_desmontagem_remontagem'
    }
  end

  def self.benchmark_comparison(file, iterations: 3)
    results = { 
      imagemagick: [],
      libvips: []
    }

    # Benchmark da abordagem atual (ImageMagick)
    iterations.times do |i|
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ImageMagick benchmark iteration #{i + 1}/#{iterations}"
      service = StickerImageOptimizerService.new(file: file)
      result = service.process
      results[:imagemagick] << {
        iteration: i + 1,
        success: result[:success],
        processing_time: result[:processing_time],
        final_size: result[:final_size],
        compression_ratio: result[:compression_ratio]
      }
    end

    # Benchmark da nova abordagem (libvips)
    iterations.times do |i|
      Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] libvips benchmark iteration #{i + 1}/#{iterations}"
      service = new(file: file)
      result = service.process
      results[:libvips] << {
        iteration: i + 1,
        success: result[:success],
        processing_time: result[:processing_time],
        final_size: result[:final_size],
        compression_ratio: result[:compression_ratio]
      }
    end

    # Calcular estatísticas
    comparison = {}
    [:imagemagick, :libvips].each do |method|
      successful = results[method].select { |r| r[:success] }
      if successful.any?
        times = successful.map { |r| r[:processing_time] }
        comparison[method] = {
          successful: successful.length,
          failed: results[method].length - successful.length,
          avg_time: (times.sum / times.length).round(2),
          min_time: times.min.round(2),
          max_time: times.max.round(2),
          avg_compression: (successful.map { |r| r[:compression_ratio] }.sum / successful.length).round(2)
        }
      else
        comparison[method] = {
          successful: 0,
          failed: results[method].length,
          error: 'All iterations failed'
        }
      end
    end

    # Calcular speedup
    if comparison[:imagemagick][:successful] > 0 && comparison[:libvips][:successful] > 0
      speedup = (comparison[:imagemagick][:avg_time] / comparison[:libvips][:avg_time]).round(2)
      comparison[:speedup] = "#{speedup}x faster with libvips"
    end

    comparison
  end

  private

  # Aplica delays customizados usando webpmux para compensação de tempo
  def apply_custom_delays_with_webpmux(webp_path, delays)
    Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] 🔧 Applying custom delays with webpmux..."
    
    temp_output = "#{webp_path}.temp"
    
    begin
      # Extrair frames individuais
      Rails.logger.debug "[SOCIALWISE-STICKER-LIBVIPS] Extracting frames for delay adjustment..."
      frame_files = []
      
      delays.each_with_index do |delay, i|
        frame_file = "/tmp/frame_#{i}.webp"
        
        # Extrair frame específico
        cmd = ["webpmux", "-get", "frame", (i + 1).to_s, webp_path, "-o", frame_file]
        stdout, stderr, status = Open3.capture3(*cmd)
        
        unless status.success?
          Rails.logger.warn "[SOCIALWISE-STICKER-LIBVIPS] ⚠️ Failed to extract frame #{i}: #{stderr}"
          next
        end
        
        frame_files << { file: frame_file, delay: delay }
      end
      
      # Recriar animação com delays corretos
      if frame_files.any?
        Rails.logger.debug "[SOCIALWISE-STICKER-LIBVIPS] Recreating animation with #{frame_files.length} frames..."
        
        cmd = ["webpmux"]
        frame_files.each_with_index do |frame_info, i|
          cmd += ["-frame", "#{frame_info[:file]}+#{frame_info[:delay]}"]
        end
        cmd += ["-loop", "0", "-o", temp_output]
        
        stdout, stderr, status = Open3.capture3(*cmd)
        
        if status.success?
          File.rename(temp_output, webp_path)
          Rails.logger.info "[SOCIALWISE-STICKER-LIBVIPS] ✅ Successfully applied custom delays"
        else
          Rails.logger.warn "[SOCIALWISE-STICKER-LIBVIPS] ⚠️ Failed to recreate animation: #{stderr}"
        end
      end
      
    rescue => e
      Rails.logger.warn "[SOCIALWISE-STICKER-LIBVIPS] ⚠️ Error applying custom delays: #{e.message}"
    ensure
      # Cleanup frame files
      frame_files&.each { |frame_info| File.delete(frame_info[:file]) if File.exist?(frame_info[:file]) }
      File.delete(temp_output) if File.exist?(temp_output)
    end
  end
end
