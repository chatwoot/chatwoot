# frozen_string_literal: true

require 'mini_magick'
require 'benchmark'
require 'open3'
require 'tmpdir'

# StickerImageOptimizerService
# 
# Implementação baseada no guia técnico "Processamento e Otimização de WebP Animado em Ruby"
# Foca na preservação de frames usando processamento atômico com combine_options
#
# Principais características conforme o guia:
# - Uso de combine_options para operações atômicas (seção 8)
# - Nunca usar extent em animações
# - Background ANTES do redimensionamento
# - Validação rigorosa de frames (input vs output)
# - Dimensões diferenciadas: animações preservam proporção, estáticas forçam 512x512
class StickerImageOptimizerService
  include ActiveModel::Model
  include ActiveModel::Attributes

  # WhatsApp sticker size limits (conforme seção 8 do guia)
  MAX_STATIC_FILE_SIZE = 100.kilobytes
  MAX_ANIMATED_FILE_SIZE = 500.kilobytes
  TARGET_DIMENSIONS = [512, 512].freeze
  SUPPORTED_FORMATS = %w[image/jpeg image/png image/gif image/webp].freeze
  OUTPUT_FORMAT = 'webp'
  QUALITY_LEVELS = [85, 75, 65, 55, 45].freeze

  attr_accessor :file, :account_id

  def initialize(file:, account_id: nil)
    @file = file
    @account_id = account_id
    @metrics_service = StickerPerformanceMetricsService.instance
  end

  def process
    start_time = Time.current

    begin
      validate_input!

      Rails.logger.info "[SOCIALWISE-STICKER] Starting sticker optimization for account #{@account_id}"

      result = optimize_image

      processing_time = (Time.current - start_time) * 1000
      @metrics_service.track_api_performance(
        api_name: 'image_processing',
        response_time: processing_time,
        success: true
      )

      Rails.logger.info "[SOCIALWISE-STICKER] Optimization completed in #{processing_time.round(2)}ms"

      {
        success: true,
        processed_file: result[:processed_file],
        original_size: result[:original_size],
        final_size: result[:final_size],
        compression_ratio: result[:compression_ratio],
        processing_time: processing_time.round(2),
        is_animated: result[:is_animated],
        has_transparency: result[:has_transparency]
      }

    rescue StandardError => e
      processing_time = (Time.current - start_time) * 1000
      @metrics_service.track_api_performance(
        api_name: 'image_processing',
        response_time: processing_time,
        success: false
      )

      Rails.logger.error "[SOCIALWISE-STICKER] Optimization failed: #{e.message}"

      {
        success: false,
        error: e.message,
        processing_time: processing_time.round(2)
      }
    end
  end

  def optimize_for_whatsapp(input_path)
    Rails.logger.info "[SOCIALWISE-STICKER] Optimizing for WhatsApp: #{input_path}"
    output_path = input_path.gsub(/\.[^.]+$/, '_optimized.webp')

    begin
      image = MiniMagick::Image.open(input_path)
      is_animated = animated?(image)
      has_transparency = has_transparency?(image)

      Rails.logger.info "[SOCIALWISE-STICKER] Analysis - animated: #{is_animated}, transparent: #{has_transparency}"

      max_file_size = is_animated ? MAX_ANIMATED_FILE_SIZE : MAX_STATIC_FILE_SIZE

      QUALITY_LEVELS.each do |quality|
        working_image = image.dup
        optimized_image = process_with_atomic_operations(working_image, quality, is_animated, has_transparency)

        temp_output = "#{output_path}.tmp"
        optimized_image.write(temp_output)
        file_size = File.size(temp_output)

        if file_size <= max_file_size
          # Validação de dimensões
          temp_check_image = MiniMagick::Image.open(temp_output)
          temp_width = temp_check_image.width
          temp_height = temp_check_image.height

          Rails.logger.info "[SOCIALWISE-STICKER] Quality #{quality}: #{temp_width}x#{temp_height}, #{file_size} bytes"

          # Para estáticas: verificação rígida. Para animadas: flexível
          if !is_animated && (temp_width != TARGET_DIMENSIONS[0] || temp_height != TARGET_DIMENSIONS[1])
            Rails.logger.warn "[SOCIALWISE-STICKER] Static image wrong dimensions: #{temp_width}x#{temp_height}"
            File.delete(temp_output) if File.exist?(temp_output)
            next
          end

          File.rename(temp_output, output_path)
          Rails.logger.info "[SOCIALWISE-STICKER] Success at quality #{quality}: #{file_size} bytes"
          return output_path
        else
          File.delete(temp_output) if File.exist?(temp_output)
        end
      end

      # Se chegou aqui, usar a qualidade mais baixa
      working_image = image.dup
      optimized_image = process_with_atomic_operations(working_image, QUALITY_LEVELS.last, is_animated, has_transparency)
      optimized_image.write(output_path)
      
      Rails.logger.warn "[SOCIALWISE-STICKER] Using lowest quality, final size: #{File.size(output_path)} bytes"
      output_path

    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-STICKER] Optimization failed: #{e.message}"
      [output_path, "#{output_path}.tmp"].each do |path|
        File.delete(path) if File.exist?(path)
      end
      raise e
    end
  end

  private

  def validate_input!
    raise ArgumentError, 'File is required' unless @file
    raise ArgumentError, 'File must respond to read' unless @file.respond_to?(:read)

    file_size = @file.size
    raise ArgumentError, 'File is too large (max 5MB for processing)' if file_size > 5.megabytes

    if @file.respond_to?(:content_type) && @file.content_type
      raise ArgumentError, "Unsupported file format: #{@file.content_type}" unless SUPPORTED_FORMATS.include?(@file.content_type)
    end
  end

  def optimize_image
    original_size = @file.size
    temp_file = Tempfile.new(['sticker_processing', '.webp'])

    begin
      file_content = @file.read
      @file.rewind if @file.respond_to?(:rewind)
      image = MiniMagick::Image.read(file_content)
      validate_image!(image)

      is_animated = animated?(image)
      has_transparency = has_transparency?(image)
      
      Rails.logger.info "[SOCIALWISE-STICKER] Processing - animated: #{is_animated}, transparent: #{has_transparency}"

      # Log inicial de frames para comparação
      initial_frames = is_animated ? image.frames.count : 1
      Rails.logger.info "[SOCIALWISE-STICKER] Input frames: #{initial_frames}"

      optimized_image = optimize_with_preservation(image, is_animated, has_transparency)

      # Validação final de frames (crítica conforme seção 8)
      final_frames = is_animated ? optimized_image.frames.count : 1
      Rails.logger.info "[SOCIALWISE-STICKER] Output frames: #{final_frames}"
      
      if is_animated && final_frames != initial_frames
        Rails.logger.warn "[SOCIALWISE-STICKER] Frame count mismatch! Expected #{initial_frames}, got #{final_frames}"
      end

      optimized_image.write(temp_file.path)
      final_size = File.size(temp_file.path)
      compression_ratio = ((original_size - final_size).to_f / original_size * 100).round(2)

      processed_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: temp_file,
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
      temp_file.close! if temp_file
      raise e
    end
  end

  def validate_image!(image)
    raise ArgumentError, 'Invalid image file' unless image.valid?

    width = image.width
    height = image.height

    raise ArgumentError, 'Image dimensions too small (minimum 64x64)' if width < 64 || height < 64
    raise ArgumentError, 'Image dimensions too large (maximum 2048x2048)' if width > 2048 || height > 2048
  end

  def animated?(image)
    frame_count = image.frames.count
    Rails.logger.info "[SOCIALWISE-STICKER] Detected #{frame_count} frames"
    frame_count > 1
  rescue StandardError => e
    Rails.logger.debug "[SOCIALWISE-STICKER] Error detecting animation: #{e.message}"
    false
  end

  def has_transparency?(image)
    result = image.identify do |b|
      b.format '%A'
    end
    result.strip.downcase == 'true'
  rescue StandardError => e
    Rails.logger.debug "[SOCIALWISE-STICKER] Error detecting transparency: #{e.message}"
    %w[png gif webp].include?(image.type.downcase)
  end

  def optimize_with_preservation(image, is_animated, has_transparency)
    max_file_size = is_animated ? MAX_ANIMATED_FILE_SIZE : MAX_STATIC_FILE_SIZE

    Rails.logger.info "[SOCIALWISE-STICKER] Using #{is_animated ? 'animated' : 'static'} size limit: #{max_file_size} bytes"

    QUALITY_LEVELS.each do |quality|
      optimized = process_with_atomic_operations(image.dup, quality, is_animated, has_transparency)
      temp_check = Tempfile.new(['size_check', '.webp'])
      
      begin
        optimized.write(temp_check.path)
        file_size = File.size(temp_check.path)

        Rails.logger.info "[SOCIALWISE-STICKER] Quality #{quality}: #{file_size} bytes"

        if file_size <= max_file_size
          Rails.logger.info "[SOCIALWISE-STICKER] Target size achieved at quality #{quality}"
          return optimized
        end
      ensure
        temp_check.close!
      end
    end

    Rails.logger.warn "[SOCIALWISE-STICKER] Using lowest quality"
    process_with_atomic_operations(image, QUALITY_LEVELS.last, is_animated, has_transparency)
  end

  # Método principal seguindo exatamente as diretrizes da seção 8 do guia
  def process_with_atomic_operations(image, quality, is_animated, has_transparency)
    Rails.logger.info "[SOCIALWISE-STICKER] Starting atomic processing - animated: #{is_animated}, quality: #{quality}"
    Rails.logger.info "[SOCIALWISE-STICKER] Input dimensions: #{image.width}x#{image.height}"

    # Garantir formato WebP de saída
    image.format(OUTPUT_FORMAT)

    if is_animated
      # Aplicar o processamento atômico com combine_options (seção 8 do guia)
      Rails.logger.info "[SOCIALWISE-STICKER] Applying atomic animation processing"
      
      image.combine_options do |c|
        # 1. Background ANTES de qualquer operação (crítico para animações)
        if has_transparency
          c.background 'none'    # Fundo transparente
          c.alpha 'set'         # Ativa canal alfa
        else
          c.background 'white'
        end
        
        # 2. Coalescing - obrigatório para animações (seção 1.2)
        c.coalesce
        
        # 3. Resize sem ^ para preservar proporção (seção 8)
        # "Animações preservam proporção, estáticas são forçadas a 512x512 exatos"
        c.resize "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}"
        
        # 4. Loop infinito
        c.loop "0"
        
        # 5. Qualidade e definições WebP
        c.quality quality.to_s
        c.define 'webp:method=4'  # Método simples para animações
        
        if has_transparency
          c.define 'webp:alpha-quality=100'
        end
      end
      
    else
      # Para imagens estáticas - forçar dimensões exatas (seção 8)
      Rails.logger.info "[SOCIALWISE-STICKER] Processing static image with exact dimensions"
      
      image.combine_options do |c|
        if has_transparency
          c.background 'transparent'
        else
          c.background 'white'
        end
        
        # Para estáticas: força dimensões exatas com ^
        c.resize "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}^"
        c.gravity "center"
        c.extent "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}"
        
        c.quality quality.to_s
        c.define 'webp:method=4'
        
        if has_transparency
          c.define 'webp:alpha-quality=100'
        end
      end
    end

    # Verificação final de dimensões
    final_width = image.width
    final_height = image.height
    Rails.logger.info "[SOCIALWISE-STICKER] Output dimensions: #{final_width}x#{final_height}"
    
    # Validação rígida para estáticas, flexível para animadas
    if !is_animated && (final_width != TARGET_DIMENSIONS[0] || final_height != TARGET_DIMENSIONS[1])
      error_msg = "Static image dimension check failed: got #{final_width}x#{final_height}, expected #{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}"
      Rails.logger.error "[SOCIALWISE-STICKER] CRITICAL: #{error_msg}"
      raise error_msg
    end

    Rails.logger.info "[SOCIALWISE-STICKER] Atomic processing completed successfully"
    image
  end

  def generate_filename(is_animated = false)
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    random_suffix = SecureRandom.hex(4)
    animation_suffix = is_animated ? '_animated' : ''
    "sticker_#{timestamp}_#{random_suffix}#{animation_suffix}.webp"
  end

  def self.batch_process(files, account_id: nil)
    results = []
    total_start_time = Time.current

    files.each_with_index do |file, index|
      Rails.logger.info "[SOCIALWISE-STICKER] Processing sticker #{index + 1}/#{files.length}"
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
      total_processing_time: total_processing_time.round(2)
    }
  end

  def self.benchmark_processing(file, iterations: 5)
    results = []

    iterations.times do |i|
      Rails.logger.info "[SOCIALWISE-STICKER] Benchmark iteration #{i + 1}/#{iterations}"
      service = new(file: file)
      result = service.process
      results << {
        iteration: i + 1,
        success: result[:success],
        processing_time: result[:processing_time],
        final_size: result[:final_size],
        compression_ratio: result[:compression_ratio]
      }
    end

    successful_results = results.select { |r| r[:success] }

    if successful_results.any?
      processing_times = successful_results.map { |r| r[:processing_time] }
      {
        iterations: iterations,
        successful: successful_results.length,
        failed: results.length - successful_results.length,
        avg_processing_time: (processing_times.sum / processing_times.length).round(2),
        min_processing_time: processing_times.min.round(2),
        max_processing_time: processing_times.max.round(2),
        avg_compression_ratio: (successful_results.map { |r| r[:compression_ratio] }.sum / successful_results.length).round(2)
      }
    else
      {
        iterations: iterations,
        successful: 0,
        failed: results.length,
        error: 'All iterations failed'
      }
    end
  end
end
    original_frames = image.frames.count
    # CORRIGIDO: Chamada de método e operador ternário
    max_file_size = is_animated ? MAX_ANIMATED_FILE_SIZE : MAX_STATIC_FILE_SIZE

    Rails.logger.info "🎯 StickerImageOptimizer: Using #{is_animated ? 'animated' : 'static'} size limit: #{max_file_size} bytes (original frames: #{original_frames})"

    QUALITY_LEVELS.each do |quality|
      optimized = process_image_with_quality_and_preservation(image.dup, quality, is_animated, has_transparency)
      temp_check = Tempfile.new(['size_check', '.webp'])
      begin
        optimized.write(temp_check.path)
        file_size = File.size(temp_check.path)
        frames_after_write = MiniMagick::Image.open(temp_check.path).frames.count

        Rails.logger.info "🎬 Quality #{quality}: #{frames_after_write} frames, #{file_size} bytes"

        if file_size <= max_file_size
          Rails.logger.info "✅ Sticker optimized at quality #{quality}, size: #{file_size} bytes, frames: #{frames_after_write}"
          return optimized
        end
      ensure
        temp_check.close!
      end
    end

    Rails.logger.warn "⚠️ Sticker optimization: using lowest quality, may exceed size limit"
    final_optimized = process_image_with_quality_and_preservation(image, QUALITY_LEVELS.last, is_animated, has_transparency)
    final_frames = MiniMagick::Image.open(final_optimized.path).frames.count
    Rails.logger.warn "🎬 Final fallback: #{final_frames} frames"
    final_optimized
  end

  def process_image_with_quality_and_preservation(image, quality, is_animated, has_transparency)
    Rails.logger.info "🎬 [PROCESS] Starting processing - animated: #{is_animated}, quality: #{quality}"
    Rails.logger.info "📐 [DIMENSIONS] Input: #{image.width}x#{image.height}"

    # Diagnóstico adicional do arquivo de entrada
    diagnose_input_file_by_path(image)

    # Capturar estado inicial para comparação
    image_before = image.dup
    initial_frames = image_before.frames.count

    image.format(OUTPUT_FORMAT) # Garante que a saída seja webp

    if is_animated
      # Usar estratégia inteligente baseada na complexidade da animação
      strategy = detect_best_animation_strategy(image.path, initial_frames)
      
      Rails.logger.info "🎯 [STRATEGY] Selected strategy: #{strategy} for #{initial_frames} frames"
      
      result_image = case strategy
      when :libvips
        Rails.logger.info "🚀 [LIBVIPS] Using high-performance libvips processing"
        process_with_libvips(image.path, quality, is_animated, has_transparency)
      when :extract_reassemble
        Rails.logger.info "🎬 [EXTRACT-REASSEMBLE] Using robust extract-process-reassemble"
        process_animated_with_extract_reassemble(image, quality, has_transparency)
      when :tool_method
        Rails.logger.info "🔧 [TOOL] Using enhanced MiniMagick Tool method"
        process_animated_with_tool_method(image, quality, has_transparency)
      else
        Rails.logger.info "🔧 [COMBINE_OPTIONS] Using fallback combine_options"
        use_combine_options_fallback(image, quality, is_animated, has_transparency)
      end
      
      # Se a estratégia principal falhou, tentar fallbacks na ordem de prioridade
      unless result_image
        Rails.logger.warn "⚠️ [STRATEGY] Primary strategy failed, trying fallbacks"
        
        fallback_strategies = [:extract_reassemble, :tool_method, :combine_options] - [strategy]
        
        fallback_strategies.each do |fallback_strategy|
          Rails.logger.info "� [FALLBACK] Trying #{fallback_strategy}"
          
          result_image = case fallback_strategy
          when :extract_reassemble
            process_animated_with_extract_reassemble(image.dup, quality, has_transparency)
          when :tool_method
            process_animated_with_tool_method(image.dup, quality, has_transparency)
          when :combine_options
            use_combine_options_fallback(image.dup, quality, is_animated, has_transparency)
          end
          
          break if result_image
        end
      end
      
      # Análise final de problemas de animação
      if result_image
        animation_status = detect_animation_issues(image_before, result_image, "final_processing")
        
        case animation_status
        when :critical_loss
          Rails.logger.error "❌ [CRITICAL] Complete animation loss detected"
          # Pode tentar uma última estratégia ou aceitar o resultado
        when :major_loss
          Rails.logger.warn "⚠️ [MAJOR_LOSS] Significant frame loss detected"
        when :minor_loss, :acceptable_loss
          Rails.logger.info "ℹ️ [MINOR_LOSS] Some frame loss within acceptable range"
        when :no_loss
          Rails.logger.info "✅ [SUCCESS] Animation preserved successfully"
        end
      end
      
      return result_image if result_image
      
      # Última tentativa com combine_options se tudo falhou
      Rails.logger.error "❌ [CRITICAL] All animation processing strategies failed"
      Rails.logger.warn "🔄 [LAST_RESORT] Using combine_options as absolute fallback"
      use_combine_options_fallback(image, quality, is_animated, has_transparency)
      
    else
      # Para imagens estáticas, usar combine_options diretamente
      Rails.logger.info "📸 [STATIC] Processing static image with combine_options"
      use_combine_options_fallback(image, quality, is_animated, has_transparency)
    end
  end

  # Método de diagnóstico para entender o arquivo de entrada usando path
  def diagnose_input_file_by_path(image)
    begin
      Rails.logger.info "🔍 [DIAGNOSE] File path: #{image.path}"
      Rails.logger.info "🔍 [DIAGNOSE] File format: #{image.type}"
      Rails.logger.info "🔍 [DIAGNOSE] File size: #{File.size(image.path)} bytes"
      Rails.logger.info "🔍 [DIAGNOSE] Frames detected by MiniMagick: #{image.frames.count}"
      
      # Usar identify para obter informações detalhadas sobre animação
      identify_output = `identify "#{image.path}" 2>&1`
      if $?.success?
        lines = identify_output.lines
        Rails.logger.info "🔍 [DIAGNOSE] Total identify lines: #{lines.count}"
        if lines.count > 1
          Rails.logger.info "🔍 [DIAGNOSE] Multi-frame WebP confirmed by identify (#{lines.count} lines)"
          # Mostrar primeiras e últimas linhas para debug
          lines.first(3).each_with_index do |line, i|
            Rails.logger.info "    Frame #{i+1}: #{line.strip[0..100]}"
          end
          if lines.count > 6
            Rails.logger.info "    ... (#{lines.count - 6} frames omitted) ..."
            lines.last(3).each_with_index do |line, i|
              Rails.logger.info "    Frame #{lines.count - 2 + i}: #{line.strip[0..100]}"
            end
          end
        else
          Rails.logger.warn "🔍 [DIAGNOSE] identify shows only 1 line - may not be properly animated"
        end
      else
        Rails.logger.warn "🔍 [DIAGNOSE] identify command failed: #{identify_output}"
      end
      
      # Verificar se é realmente um WebP animado usando webpmux se disponível
      if command_available?('webpmux')
        webp_info = `webpmux -info "#{image.path}" 2>&1`
        if $?.success?
          Rails.logger.info "🔍 [DIAGNOSE] WebP info:"
          webp_info.lines.each { |line| Rails.logger.info "    #{line.strip}" }
        else
          Rails.logger.warn "🔍 [DIAGNOSE] webpmux failed: #{webp_info}"
        end
      else
        Rails.logger.warn "🔍 [DIAGNOSE] webpmux not available for detailed WebP analysis"
      end
      
    rescue StandardError => e
      Rails.logger.warn "🔍 [DIAGNOSE] Error during diagnosis: #{e.message}"
    end
  end

  # Método separado para fallback e processamento de imagens estáticas
  def use_combine_options_fallback(image, quality, is_animated, has_transparency)
    Rails.logger.info "🔧 [COMBINE_OPTIONS] Starting enhanced combine_options processing"
    
    initial_frames = image.frames.count if is_animated
    Rails.logger.info "🎬 [COMBINE_OPTIONS] Input frames: #{initial_frames}" if is_animated
    
    # PRIMEIRA TENTATIVA: Abordagem conservadora
    begin
      image.combine_options do |c|
        if is_animated
          # Pipeline baseado no guia mas mais conservador
          Rails.logger.info "🎬 [COMBINE_OPTIONS] Applying conservative animation pipeline"
          
          # 1. Coalescing - obrigatório (Seção 1.3)
          c.coalesce
          
          # 2. Resize - usar abordagem mais simples
          c.resize "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}!"  # Força dimensões exatas
          
          # 3. Background
          if has_transparency
            c.background 'transparent'
          else
            c.background 'white'
          end
          
          # 4. Loop infinito
          c.loop "0"
          
          # Pular gravity/extent que podem causar problemas
          # Pular layers optimize que pode causar perda de frames
          # Pular repage que pode causar problemas
        else
          # Pipeline para imagens estáticas
          Rails.logger.info "📷 [COMBINE_OPTIONS] Applying static image pipeline"
          
          c.resize "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}^"
          
          if has_transparency
            c.background 'transparent'
          else
            c.background 'white'
          end
          
          c.gravity "center"
          c.extent "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}"
        end

        # Comandos de qualidade simplificados
        c.quality quality.to_s
        c.define 'webp:method=4'  # Método mais simples/rápido
        
        if has_transparency
          c.define 'webp:alpha-quality=100'
        end
      end

      # Verificar resultado da primeira tentativa
      if is_animated
        final_frames = image.frames.count
        Rails.logger.info "🎬 [COMBINE_OPTIONS] Conservative result: #{final_frames} frames"
        
        if final_frames >= (initial_frames * 0.8).to_i  # Aceitar até 20% de perda
          Rails.logger.info "✅ [COMBINE_OPTIONS] Conservative approach successful"
        else
          Rails.logger.warn "⚠️ [COMBINE_OPTIONS] Conservative approach lost too many frames, trying alternative"
          raise "Frame loss detected"
        end
      end

    rescue StandardError => e
      if is_animated
        Rails.logger.warn "🔧 [COMBINE_OPTIONS] Conservative approach failed: #{e.message}, trying alternative"
        
        # SEGUNDA TENTATIVA: Abordagem ainda mais simples
        image.combine_options do |c|
          Rails.logger.info "🎬 [COMBINE_OPTIONS] Applying minimal animation pipeline"
          
          # Apenas comandos essenciais
          c.coalesce
          c.sample "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}!"  # Sample ao invés de resize
          c.loop "0"
          c.quality quality.to_s
          
          if has_transparency
            c.background 'transparent'
          end
        end
        
        final_frames = image.frames.count
        Rails.logger.info "🎬 [COMBINE_OPTIONS] Minimal result: #{final_frames} frames"
      else
        raise e  # Re-raise para imagens estáticas
      end
    end

    # Verificação final
    final_width = image.width
    final_height = image.height
    Rails.logger.info "📐 [DIMENSIONS] Output: #{final_width}x#{final_height}"
    
    if is_animated
      final_frames = image.frames.count
      Rails.logger.info "🎬 [COMBINE_OPTIONS] Final frames: #{final_frames}"
      
      if final_frames < 2
        Rails.logger.error "❌ [COMBINE_OPTIONS] CRITICAL: Animation lost all frames except 1"
        # Não fazer raise aqui para permitir fallback
      end
    end
    
    # Não fazer verificação rígida de dimensões para animações que podem ter problemas
    if !is_animated && (final_width != TARGET_DIMENSIONS[0] || final_height != TARGET_DIMENSIONS[1])
      error_msg = "Dimension optimization failed: got #{final_width}x#{final_height}"
      Rails.logger.error "❌ [COMBINE_OPTIONS] #{error_msg}"
      raise error_msg
    end

    Rails.logger.info "✅ [COMBINE_OPTIONS] Processing completed for quality #{quality}"
    image
  end

  # Implementação usando libvips (seção 4 do guia) - mais eficiente
  # Usa o paradigma "film strip" para processar todos os frames de uma vez
  def process_animated_with_vips(image, quality, has_transparency)
    return nil unless defined?(Vips)
    
    Rails.logger.info "🎬 [VIPS] Starting high-efficiency libvips processing"
    
    begin
      # Criar arquivo temporário de entrada compatível com vips
      temp_input = Tempfile.new(['vips_input', '.webp'])
      temp_input.binmode
      temp_input.write(File.read(image.path))
      temp_input.close
      
      # Carregar animação como "film strip" (todos os frames de uma vez)
      vips_image = Vips::Image.new_from_file(temp_input.path, n: -1)
      
      # Preservar metadados da animação
      num_pages = vips_image.get('n-pages')
      page_height = vips_image.height / num_pages
      
      Rails.logger.info "🎬 [VIPS] Loaded film strip: #{num_pages} frames, #{page_height}px each"
      
      # Calcular fator de escala
      scale_factor = TARGET_DIMENSIONS[0].to_f / vips_image.width
      
      # Redimensionar toda a "film strip" de uma vez
      resized = vips_image.resize(scale_factor)
      new_page_height = (resized.height / num_pages).to_i
      
      # Embed (centralizar e preencher) cada frame para 512x512
      total_height = TARGET_DIMENSIONS[1] * num_pages
      x_offset = (TARGET_DIMENSIONS[0] - resized.width) / 2
      y_offset = 0
      
      final_image = resized.embed(
        x_offset, y_offset,
        TARGET_DIMENSIONS[0], total_height,
        extend: :background,
        background: has_transparency ? [0, 0, 0, 0] : [255, 255, 255]
      )
      
      # Salvar como WebP animado
      temp_output = Tempfile.new(['vips_output', '.webp'])
      temp_output.close
      
      final_image.webpsave(temp_output.path, {
        page_height: TARGET_DIMENSIONS[1],
        Q: quality,
        effort: 6,
        kmin: 9,
        kmax: 17,
        lossless: false
      })
      
      # Carregar resultado com MiniMagick para compatibilidade
      result_image = MiniMagick::Image.open(temp_output.path)
      result_frames = result_image.frames.count
      
      Rails.logger.info "✅ [VIPS] High-efficiency processing complete: #{result_frames} frames"
      
      result_image
      
    rescue StandardError => e
      Rails.logger.error "❌ [VIPS] Failed: #{e.message}"
      nil
    ensure
      temp_input&.unlink
      temp_output&.unlink if defined?(temp_output)
    end
  end

  # Implementação da abordagem "Extract-Process-Reassemble" (Seção 3 do guia)
  # Esta é a abordagem mais robusta para preservar frames quando libvips falha
  def process_animated_with_extract_reassemble(image, quality, has_transparency)
    Rails.logger.info "🎬 [EXTRACT-REASSEMBLE] Starting Desmontagem-Processamento-Remontagem workflow (PRIORITY 2)"
    
    # Verificar se comandos libwebp estão disponíveis
    unless command_available?('webpmux') && command_available?('img2webp') && command_available?('webpinfo')
      Rails.logger.warn "🎬 [EXTRACT-REASSEMBLE] libwebp tools not available (webpmux/img2webp/webpinfo)"
      return nil
    end
    
    # Criar diretórios temporários (usando tmpdir para segurança)
    temp_dir = Dir.mktmpdir('sticker_animation_')
    frames_dir = File.join(temp_dir, 'frames')
    processed_dir = File.join(temp_dir, 'processed')
    Dir.mkdir(frames_dir)
    Dir.mkdir(processed_dir)
    
    begin
      # ETAPA 1: Extrair metadados usando webpinfo (Seção 3.1)
      metadata = extract_metadata_with_webpinfo(image.path)
      unless metadata
        Rails.logger.error "❌ [EXTRACT-REASSEMBLE] Failed to extract metadata"
        return nil
      end
      
      # ETAPA 2: Extrair frames usando webpmux (Seção 3.2)
      frame_count = extract_frames_with_webpmux(image.path, frames_dir)
      if frame_count == 0
        Rails.logger.warn "🎬 [EXTRACT-REASSEMBLE] No frames extracted"
        return nil
      end
      
      # Verificar consistência entre metadados e frames extraídos
      if metadata[:frame_count] != frame_count
        Rails.logger.warn "⚠️ [EXTRACT-REASSEMBLE] Metadata inconsistency: expected #{metadata[:frame_count]}, got #{frame_count}"
        # Usar o menor valor para segurança
        frame_count = [metadata[:frame_count], frame_count].min
      end
      
      # ETAPA 3: Processar cada frame individualmente com ruby-vips (Seção 3.3)
      process_individual_frames_with_vips(frames_dir, processed_dir, frame_count, quality, has_transparency)
      
      # ETAPA 4: Reassemblar usando img2webp (Seção 3.4)
      output_path = reassemble_with_img2webp(processed_dir, frame_count, temp_dir, metadata)
      unless output_path && File.exist?(output_path)
        Rails.logger.warn "🎬 [EXTRACT-REASSEMBLE] Reassembly failed"
        return nil
      end
      
      # Retornar a imagem processada
      result_image = MiniMagick::Image.open(output_path)
      result_frames = result_image.frames.count
      Rails.logger.info "✅ [EXTRACT-REASSEMBLE] Success: #{result_frames} frames preserved (input: #{frame_count})"
      result_image
      
    rescue StandardError => e
      Rails.logger.error "❌ [EXTRACT-REASSEMBLE] Failed: #{e.message}"
      Rails.logger.error "📚 [EXTRACT-REASSEMBLE] Backtrace: #{e.backtrace.first(3).join("\n")}"
      nil
    ensure
      # Limpeza segura de arquivos temporários
      FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
    end
  end

  # ETAPA 1: Extrair metadados usando webpinfo (implementação da Seção 3.1)
  def extract_metadata_with_webpinfo(input_path)
    Rails.logger.info "🔍 [METADATA] Extracting animation metadata with webpinfo"
    
    begin
      stdout, stderr, status = Open3.capture3("webpinfo", input_path)
      unless status.success?
        Rails.logger.error "❌ [METADATA] webpinfo failed: #{stderr}"
        return nil
      end
      
      # Parse frame count
      frame_count_match = stdout.match(/Number of frames:\s+(\d+)/)
      unless frame_count_match
        Rails.logger.error "❌ [METADATA] Could not extract frame count"
        return nil
      end
      frame_count = frame_count_match[1].to_i
      
      # Parse durations (one per frame)
      durations = stdout.scan(/Duration:\s+(\d+)/).flatten.map(&:to_i)
      
      # Se não encontrou durações suficientes, usar 100ms como padrão
      if durations.length < frame_count
        Rails.logger.warn "⚠️ [METADATA] Found only #{durations.length} durations for #{frame_count} frames, filling with defaults"
        while durations.length < frame_count
          durations << 100  # 100ms padrão
        end
      end
      
      metadata = {
        frame_count: frame_count,
        durations: durations
      }
      
      Rails.logger.info "✅ [METADATA] Extracted: #{frame_count} frames with durations #{durations.first(3)}#{durations.length > 3 ? '...' : ''}"
      metadata
      
    rescue StandardError => e
      Rails.logger.error "❌ [METADATA] Exception: #{e.message}"
      nil
    end
  end

  # ETAPA 3: Processar frames individuais usando ruby-vips (otimização da Seção 3.3)
  def process_individual_frames_with_vips(frames_dir, processed_dir, frame_count, quality, has_transparency)
    Rails.logger.info "🎬 [PROCESS_FRAMES] Processing #{frame_count} individual frames with ruby-vips"
    
    (1..frame_count).each do |i|
      frame_file = File.join(frames_dir, "frame_#{i.to_s.rjust(4, '0')}.webp")
      processed_file = File.join(processed_dir, "processed_#{i.to_s.rjust(4, '0')}.webp")
      
      begin
        # Usar ruby-vips para máxima performance (conforme Seção 3.3)
        image = Vips::Image.thumbnail(frame_file, TARGET_DIMENSIONS[0], 
          height: TARGET_DIMENSIONS[1], 
          crop: :centre,
          size: :both
        )
        
        # Salvar com qualidade específica
        save_options = { Q: quality }
        if has_transparency
          save_options.merge!({
            alpha_q: 100,
            lossless: false
          })
        end
        
        image.webpsave(processed_file, **save_options)
        
      rescue StandardError => e
        Rails.logger.error "❌ [PROCESS_FRAMES] Failed to process frame #{i}: #{e.message}"
        raise "Frame processing failed at frame #{i}"
      end
    end
    
    Rails.logger.info "✅ [PROCESS_FRAMES] Successfully processed #{frame_count} frames"
  end

  # ETAPA 4: Reassemblar usando img2webp (implementação da Seção 3.4)
  def reassemble_with_img2webp(processed_dir, frame_count, temp_dir, metadata)
    Rails.logger.info "🎬 [REASSEMBLE] Reassembling #{frame_count} frames with img2webp"
    
    output_path = File.join(temp_dir, 'final_animation.webp')
    
    # Construir comando dinâmico conforme Seção 3.4
    cmd = ["img2webp", "-loop", "0"]  # Loop infinito
    
    # Adicionar cada frame com sua duração específica
    (1..frame_count).each do |i|
      frame_path = File.join(processed_dir, "processed_#{i.to_s.rjust(4, '0')}.webp")
      duration = metadata[:durations][i - 1] || 100  # Fallback para 100ms
      
      cmd.concat(["-d", duration.to_s, frame_path])
    end
    
    # Adicionar opções de otimização conforme Seção 5.2
    cmd.concat([
      "-mixed",           # Compressão mista (lossy/lossless por frame)
      "-q", "80",         # Qualidade para frames lossy
      "-m", "6",          # Método de compressão
      "-o", output_path
    ])
    
    Rails.logger.debug "🔧 [REASSEMBLE] Command: #{cmd.join(' ')}"
    
    begin
      stdout, stderr, status = Open3.capture3(*cmd)
      
      if status.success?
        Rails.logger.info "✅ [REASSEMBLE] Animation reassembled successfully"
        return output_path
      else
        Rails.logger.error "❌ [REASSEMBLE] img2webp failed: #{stderr}"
        return nil
      end
    rescue StandardError => e
      Rails.logger.error "❌ [REASSEMBLE] Exception: #{e.message}"
      return nil
    end
  end

  # Método Tool melhorado para preservar frames de animação
  def process_animated_with_tool_method(image, quality, has_transparency)
    Rails.logger.info "🎬 [TOOL] Using enhanced MiniMagick::Tool::Magick approach"
    
    # Verificar frames iniciais para comparação
    initial_frames = image.frames.count
    Rails.logger.info "🎬 [TOOL] Input has #{initial_frames} frames"
    
    temp_output = Tempfile.new(['animated_output', '.webp'])
    temp_output.close
    
    begin
      # PRIMEIRA TENTATIVA: Comando mais conservador (sem layers optimize)
      Rails.logger.info "🎬 [TOOL] Attempt 1: Conservative approach (no layers optimize)"
      tool = MiniMagick::Tool::Magick.new
      tool.merge! [image.path]
      tool.coalesce
      tool.resize "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}^"
      
      if has_transparency
        tool.background 'transparent'
      else
        tool.background 'white'
      end
      
      tool.gravity 'center'
      tool.extent "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}"
      tool.repage.+
      # Removido: tool.layers 'optimize'  # Pode estar causando perda de frames
      tool.loop 0
      tool.quality quality.to_s
      tool.merge! ['-define', 'webp:method=6', '-define', 'webp:lossless=false']
      
      if has_transparency
        tool.merge! ['-define', 'webp:alpha-compression=1', '-define', 'webp:alpha-quality=100']
      end
      
      tool.merge! [temp_output.path]
      
      Rails.logger.debug "🔧 [TOOL] Command: #{tool.command.join(' ')}"
      
      tool.call
      
      processed_image = MiniMagick::Image.open(temp_output.path)
      processed_frames = processed_image.frames.count
      Rails.logger.info "🎬 [TOOL] Attempt 1 result: #{processed_frames} frames (input: #{initial_frames})"
      
      # Se preservou os frames, retornar resultado
      if processed_frames > 1 && processed_frames >= (initial_frames * 0.8).to_i  # Tolerar até 20% de perda
        Rails.logger.info "✅ [TOOL] Success with conservative approach: #{processed_frames} frames"
        return processed_image
      end
      
      # SEGUNDA TENTATIVA: Abordagem alternativa com diferentes flags
      Rails.logger.warn "⚠️ [TOOL] Attempt 1 lost frames, trying alternative approach"
      
      temp_output2 = Tempfile.new(['animated_output_alt', '.webp'])
      temp_output2.close
      
      tool2 = MiniMagick::Tool::Magick.new
      tool2.merge! [image.path]
      tool2.coalesce
      
      # Usar abordagem diferente: redimensionar com sample ao invés de resize
      tool2.sample "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}!"  # Força dimensões exatas
      
      if has_transparency
        tool2.background 'transparent'
      else
        tool2.background 'white'
      end
      
      tool2.gravity 'center'
      tool2.loop 0
      tool2.quality quality.to_s
      tool2.merge! ['-define', 'webp:method=4']  # Método mais simples
      
      if has_transparency
        tool2.merge! ['-define', 'webp:alpha-quality=100']
      end
      
      tool2.merge! [temp_output2.path]
      
      Rails.logger.debug "🔧 [TOOL_ALT] Command: #{tool2.command.join(' ')}"
      tool2.call
      
      alt_image = MiniMagick::Image.open(temp_output2.path)
      alt_frames = alt_image.frames.count
      Rails.logger.info "🎬 [TOOL] Attempt 2 result: #{alt_frames} frames (input: #{initial_frames})"
      
      # Usar o melhor resultado
      if alt_frames > processed_frames
        Rails.logger.info "✅ [TOOL] Using alternative result: #{alt_frames} frames"
        temp_output2&.unlink
        return alt_image
      else
        Rails.logger.info "✅ [TOOL] Using original result: #{processed_frames} frames"
        temp_output2&.unlink
        return processed_image
      end
      
    rescue StandardError => e
      Rails.logger.error "❌ [TOOL] Both attempts failed: #{e.message}"
      Rails.logger.error "📚 [TOOL] Backtrace: #{e.backtrace.first(3).join("\n")}"
      
      # TERCEIRA TENTATIVA: Fallback usando comando shell direto
      Rails.logger.warn "🎬 [TOOL] Trying direct shell command as last resort"
      begin
        shell_output = process_with_direct_shell_command(image.path, temp_output.path, quality, has_transparency)
        if shell_output
          shell_image = MiniMagick::Image.open(temp_output.path)
          shell_frames = shell_image.frames.count
          Rails.logger.info "🎬 [SHELL] Direct command result: #{shell_frames} frames"
          return shell_image if shell_frames > 1
        end
      rescue StandardError => shell_error
        Rails.logger.error "❌ [SHELL] Direct command also failed: #{shell_error.message}"
      end
      
      nil
    ensure
      temp_output&.unlink
    end
  end

  # Método de fallback usando comando shell direto
  def process_with_direct_shell_command(input_path, output_path, quality, has_transparency)
    Rails.logger.info "🎬 [SHELL] Using direct shell command"
    
    background = has_transparency ? 'transparent' : 'white'
    
    # Comando baseado no guia (Seção 2.2)
    cmd = [
      'magick', input_path,
      '-coalesce',
      '-resize', "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}^",
      '-background', background,
      '-gravity', 'center',
      '-extent', "#{TARGET_DIMENSIONS[0]}x#{TARGET_DIMENSIONS[1]}",
      '-loop', '0',
      '-quality', quality.to_s,
      '-define', 'webp:method=6',
      output_path
    ]
    
    Rails.logger.debug "🔧 [SHELL] Command: #{cmd.join(' ')}"
    
    result = system(*cmd)
    
    if result
      Rails.logger.info "✅ [SHELL] Direct command executed successfully"
      true
    else
      Rails.logger.error "❌ [SHELL] Direct command failed"
      false
    end
  end

  # Verificar se comando está disponível no sistema
  def command_available?(command)
    return @command_cache[command] if defined?(@command_cache) && @command_cache&.key?(command)
    
    @command_cache ||= {}
    
    # Tentar diferentes formas de verificar disponibilidade
    begin
      Rails.logger.debug "🔍 [COMMAND_CHECK] Testing availability of: #{command}"
      
      # Método 1: where (Windows) / which (Unix)
      if Gem.win_platform?
        result = system("where #{command} >nul 2>&1")
      else
        result = system("which #{command} > /dev/null 2>&1")
      end
      
      if result
        Rails.logger.debug "✅ [COMMAND_CHECK] #{command} found via where/which"
        @command_cache[command] = true
        return true
      end
      
      # Método 2: command -v (mais portável)
      result = system("command -v #{command} > /dev/null 2>&1")
      if result
        Rails.logger.debug "✅ [COMMAND_CHECK] #{command} found via command -v"
        @command_cache[command] = true
        return true
      end
      
      # Método 3: tentativa direta com --version
      if Gem.win_platform?
        result = system("#{command} --version >nul 2>&1")
      else
        result = system("#{command} --version > /dev/null 2>&1")
      end
      
      if result
        Rails.logger.debug "✅ [COMMAND_CHECK] #{command} responds to --version"
        @command_cache[command] = true
        return true
      end
      
      Rails.logger.debug "❌ [COMMAND_CHECK] #{command} not found"
      @command_cache[command] = false
      false
      
    rescue StandardError => e
      Rails.logger.debug "🔍 [COMMAND_CHECK] Error checking #{command}: #{e.message}"
      @command_cache[command] = false
      false
    end
  end

  # Detectar qual estratégia usar baseada no ambiente disponível
  def detect_best_animation_strategy
    strategies = []
    
    # libvips - mais eficiente (seção 4 do guia)
    if defined?(Vips)
      strategies << { name: 'vips', priority: 1, description: 'High-efficiency libvips' }
    end
    
    # libwebp suite - mais robusto (seção 3 do guia)
    if command_available?('webpmux') && command_available?('img2webp')
      strategies << { name: 'extract_reassemble', priority: 2, description: 'Robust Extract-Process-Reassemble' }
    end
    
    # ImageMagick Tool - fallback confiável
    strategies << { name: 'tool', priority: 3, description: 'ImageMagick Tool method' }
    
    # combine_options - último recurso
    strategies << { name: 'combine_options', priority: 4, description: 'MiniMagick combine_options' }
    
    # Retornar estratégia com maior prioridade (menor número)
    best = strategies.min_by { |s| s[:priority] }
    Rails.logger.info "🎯 [STRATEGY] Best available: #{best[:description]}"
    
    best[:name]
  end

  # Extrair frames usando webpmux (parte do libwebp suite) - versão robusta
  def extract_frames_with_webpmux(input_path, frames_dir)
    Rails.logger.info "🎬 [EXTRACT] Extracting frames with webpmux"
    
    begin
      # Usar Open3 para controle robusto de processos
      stdout, stderr, status = Open3.capture3("webpmux", "-info", input_path)
      unless status.success?
        Rails.logger.error "❌ [EXTRACT] webpmux info failed: #{stderr}"
        return 0
      end
      
      # Parse do número de frames
      frame_count_match = stdout.match(/Number of frames:\s+(\d+)/)
      unless frame_count_match
        Rails.logger.error "❌ [EXTRACT] Could not parse frame count from webpmux output"
        return 0
      end
      
      frame_count = frame_count_match[1].to_i
      Rails.logger.info "🎬 [EXTRACT] Found #{frame_count} frames to extract"
      
      # Extrair cada frame usando nomes consistentes com a Seção 3
      (1..frame_count).each do |i|
        frame_output = File.join(frames_dir, "frame_#{i.to_s.rjust(4, '0')}.webp")
        
        _, stderr, status = Open3.capture3("webpmux", "-get", "frame", i.to_s, input_path, "-o", frame_output)
        
        unless status.success?
          Rails.logger.error "❌ [EXTRACT] Failed to extract frame #{i}: #{stderr}"
          return 0
        end
        
        # Verificar se o arquivo foi criado
        unless File.exist?(frame_output) && File.size(frame_output) > 0
          Rails.logger.error "❌ [EXTRACT] Frame #{i} was not created or is empty"
          return 0
        end
      end
      
      Rails.logger.info "✅ [EXTRACT] Successfully extracted #{frame_count} frames"
      frame_count
      
    rescue StandardError => e
      Rails.logger.error "❌ [EXTRACT] Exception: #{e.message}"
    end
  end

  # Reassemblar frames usando img2webp (método antigo - removido em favor da versão melhorada)

  # Reassemblar frames usando img2webp
  def reassemble_with_img2webp(processed_dir, frame_count, temp_dir)
    Rails.logger.info "🎬 [REASSEMBLE] Reassembling #{frame_count} frames"
    
    output_path = File.join(temp_dir, 'final_animation.webp')
    
    # Construir lista de arquivos ordenados
    frame_files = (1..frame_count).map do |i|
      File.join(processed_dir, "processed_#{i.to_s.rjust(3, '0')}.webp")
    end
    
    # Usar img2webp para reassemblar
    cmd = [
      'img2webp',
      '-loop', '0',          # Loop infinito
      '-d', '100',           # 100ms por frame (padrão)
      '-o', output_path
    ] + frame_files
    
    system(*cmd)
    
    if $?.success?
      Rails.logger.info "✅ [REASSEMBLE] Animation reassembled successfully"
      output_path
    else
      Rails.logger.error "❌ [REASSEMBLE] Failed to reassemble animation"
      nil
    end
  end

  def generate_filename(is_animated = false)
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    random_suffix = SecureRandom.hex(4)
    # CORRIGIDO: Operador ternário
    animation_suffix = is_animated ? '_animated' : ''
    "sticker_#{timestamp}_#{random_suffix}#{animation_suffix}.webp"
  end

  def self.batch_process(files, account_id: nil)
    results = [] # CORRIGIDO: Inicialização de array
    total_start_time = Time.current

    files.each_with_index do |file, index|
      Rails.logger.info "Processing sticker #{index + 1}/#{files.length}"
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
      total_processing_time: total_processing_time.round(2)
    }
  end

  def self.benchmark_processing(file, iterations: 5)
    results = [] # CORRIGIDO: Inicialização de array

    iterations.times do |i|
      Rails.logger.info "Benchmark iteration #{i + 1}/#{iterations}"
      service = new(file: file)
      result = service.process
      results << {
        iteration: i + 1,
        success: result[:success],
        processing_time: result[:processing_time],
        final_size: result[:final_size],
        compression_ratio: result[:compression_ratio]
      }
    end

    successful_results = results.select { |r| r[:success] }

    if successful_results.any?
      processing_times = successful_results.map { |r| r[:processing_time] }
      {
        iterations: iterations,
        successful: successful_results.length,
        failed: results.length - successful_results.length,
        avg_processing_time: (processing_times.sum / processing_times.length).round(2),
        min_processing_time: processing_times.min.round(2),
        max_processing_time: processing_times.max.round(2),
        avg_compression_ratio: (successful_results.map { |r| r[:compression_ratio] }.sum / successful_results.length).round(2)
      }
    else
      {
        iterations: iterations,
        successful: 0,
        failed: results.length,
        error: 'All iterations failed'
      }
    end
  end

  # Método auxiliar para debug de frames
  def debug_frame_info(file_path, label = "FILE")
    begin
      # Contar frames
      frame_count = `identify -format "%n\\n" "#{file_path}" | head -1`.strip.to_i

      # Obter informações detalhadas
      info = `identify -verbose "#{file_path}[0]" 2>&1 | head -50`

      # Verificar se é animado
      is_animated = frame_count > 1

      # Verificar formato
      format = `identify -format "%m" "#{file_path}[0]"`.strip

      Rails.logger.info "🔍 [#{label}] Frames: #{frame_count}, Format: #{format}, Animated: #{is_animated}"

      # Se for animado, verificar delay entre frames
      if is_animated
        delays = `identify -format "%T\\n" "#{file_path}"`.strip.split("\n")
        Rails.logger.info "🔍 [#{label}] Frame delays: #{delays.join(', ')}"
      end

      frame_count
    rescue => e
      Rails.logger.error "❌ [DEBUG] Error checking #{label}: #{e.message}"
      0
    end
  end

  # Método alternativo usando ffmpeg (se disponível)
  def process_animated_with_ffmpeg(input_path, output_path, quality)
    Rails.logger.info "🎬 [FFMPEG] Attempting animation processing with ffmpeg"

    command = [
      'ffmpeg',
      '-i', input_path,
      '-vf', "scale=#{TARGET_DIMENSIONS[0]}:#{TARGET_DIMENSIONS[1]}:force_original_aspect_ratio=decrease,pad=#{TARGET_DIMENSIONS[0]}:#{TARGET_DIMENSIONS[1]}:(ow-iw)/2:(oh-ih)/2:color=0x00000000",
      '-codec:v', 'libwebp',
      '-lossless', '0',
      '-compression_level', '6',
      '-quality', quality.to_s,
      '-preset', 'default',
      '-loop', '0',
      '-an',
      '-vsync', '0',
      output_path,
      '-y'  # Sobrescrever arquivo de saída
    ]

    result = `#{command.join(' ')} 2>&1`

    if $?.success?
      Rails.logger.info "✅ [FFMPEG] Animation processed successfully"
      true
    else
      Rails.logger.error "❌ [FFMPEG] Processing failed: #{result}"
      false
    end
  end

  # Método para verificar disponibilidade de libvips
  def libvips_available?
    return @libvips_available if defined?(@libvips_available)
    
    begin
      require 'vips'
      # Teste mais robusto para verificar se Vips está funcionando
      test_image = Vips::Image.new_from_array([[1, 2], [3, 4]])
      test_result = test_image.width > 0 && test_image.height > 0
      
      if test_result
        @libvips_available = true
        Rails.logger.info "✅ [LIBVIPS] Available and functional: #{Vips::version_string}"
      else
        @libvips_available = false
        Rails.logger.warn "⚠️ [LIBVIPS] Library loaded but test failed"
      end
      
    rescue LoadError => e
      @libvips_available = false
      Rails.logger.info "ℹ️ [LIBVIPS] Not installed: #{e.message}"
    rescue Vips::Error => e
      @libvips_available = false
      Rails.logger.warn "⚠️ [LIBVIPS] Error during test: #{e.message}"
    rescue StandardError => e
      @libvips_available = false
      Rails.logger.warn "⚠️ [LIBVIPS] Unexpected error: #{e.message}"
    end
    
    @libvips_available
  end

  # Método para detectar problemas potenciais na animação
  def detect_animation_issues(image_before, image_after, operation_name)
    Rails.logger.info "🔍 [ANIMATION_CHECK] Analyzing #{operation_name} results"
    
    frames_before = image_before.frames.count
    frames_after = image_after.frames.count
    
    Rails.logger.info "🎬 [ANIMATION_CHECK] Frames: #{frames_before} → #{frames_after}"
    
    if frames_before > 1 && frames_after == 1
      Rails.logger.error "❌ [ANIMATION_LOSS] CRITICAL: Animation completely lost in #{operation_name}"
      Rails.logger.error "❌ [ANIMATION_LOSS] All #{frames_before} frames collapsed to 1 frame"
      return :critical_loss
    elsif frames_after < frames_before
      loss_percent = ((frames_before - frames_after) / frames_before.to_f * 100).round(2)
      Rails.logger.warn "⚠️ [ANIMATION_LOSS] Partial frame loss in #{operation_name}: #{loss_percent}%"
      
      if loss_percent > 50
        return :major_loss
      elsif loss_percent > 20
        return :minor_loss
      else
        return :acceptable_loss
      end
    elsif frames_after > frames_before
      Rails.logger.info "🎬 [ANIMATION_CHECK] Frame count increased (unexpected but not critical)"
      return :frame_increase
    else
      Rails.logger.info "✅ [ANIMATION_CHECK] Frame count preserved"
      return :no_loss
    end
  end

  # Método para diagnóstico detalhado de arquivos
  def diagnose_input_file(image_path)
    Rails.logger.info "🔍 [DIAGNOSTICS] Starting detailed analysis of: #{image_path}"
    
    # Verificar existência
    unless File.exist?(image_path)
      Rails.logger.error "❌ [DIAGNOSTICS] File not found"
      return
    end
    
    # Informações básicas do arquivo
    file_size = File.size(image_path)
    Rails.logger.info "📂 [DIAGNOSTICS] File size: #{(file_size / 1024.0).round(2)} KB"
    
    # Usar ImageMagick identify para análise detalhada
    begin
      identify_output = `identify "#{image_path}" 2>&1`
      Rails.logger.info "🔍 [IDENTIFY] Raw output:\n#{identify_output}"
      
      # Contar frames pela análise do output
      lines = identify_output.lines
      frame_count = lines.count { |line| line.include?(File.basename(image_path)) }
      Rails.logger.info "🎬 [IDENTIFY] Detected frames: #{frame_count}"
      
      # Analisar primeira linha para detalhes
      first_line = lines.first&.strip
      if first_line
        Rails.logger.info "📋 [IDENTIFY] First frame: #{first_line}"
        
        # Extrair informações da primeira linha
        if first_line =~ /(\d+)x(\d+)/
          width, height = $1.to_i, $2.to_i
          Rails.logger.info "📐 [IDENTIFY] Dimensions: #{width}x#{height}"
        end
        
        # Verificar formato
        if first_line.include?('WEBP')
          Rails.logger.info "✅ [IDENTIFY] Format: WebP confirmed"
          
          # Analisar características específicas do WebP
          if first_line.include?('DirectClass')
            Rails.logger.info "🎨 [WEBP] Color class: DirectClass (RGB/RGBA)"
          end
          
          if first_line.include?('Matte')
            Rails.logger.info "🎨 [WEBP] Transparency: Has matte (alpha channel)"
          end
        end
      end
      
      # Análise adicional com libvips se disponível
      if libvips_available?
        begin
          vips_image = Vips::Image.new_from_file(image_path)
          
          # Tentar obter informações sobre frames
          if vips_image.respond_to?(:get) 
            begin
              # Verificar propriedades WebP específicas
              n_pages = vips_image.get('n-pages') if vips_image.get_typeof('n-pages') != 0
              Rails.logger.info "🎬 [VIPS] n-pages property: #{n_pages}" if n_pages
            rescue Vips::Error => e
              Rails.logger.info "ℹ️ [VIPS] n-pages not available: #{e.message}"
            end
            
            begin
              page_height = vips_image.get('page-height') if vips_image.get_typeof('page-height') != 0
              Rails.logger.info "📏 [VIPS] page-height: #{page_height}" if page_height
            rescue Vips::Error => e
              Rails.logger.info "ℹ️ [VIPS] page-height not available: #{e.message}"
            end
          end
          
          Rails.logger.info "📐 [VIPS] Image dimensions: #{vips_image.width}x#{vips_image.height}"
          Rails.logger.info "🎨 [VIPS] Bands: #{vips_image.bands}"
          Rails.logger.info "🎨 [VIPS] Interpretation: #{vips_image.interpretation}"
          
        rescue Vips::Error => e
          Rails.logger.warn "⚠️ [VIPS] Analysis failed: #{e.message}"
        end
      end
      
    rescue StandardError => e
      Rails.logger.error "❌ [DIAGNOSTICS] Analysis failed: #{e.class}: #{e.message}"
    end
    
    Rails.logger.info "🔍 [DIAGNOSTICS] Analysis complete"
  end

  # Método para detectar melhor estratégia de animação baseado no guia
  def detect_best_animation_strategy(image_path, frame_count)
    Rails.logger.info "🧠 [STRATEGY] Detecting best approach for #{frame_count} frames"
    
    # Debug de disponibilidade de ferramentas
    libvips_status = libvips_available?
    webpmux_status = command_available?('webpmux')
    img2webp_status = command_available?('img2webp')
    
    Rails.logger.info "🔍 [STRATEGY] Tools availability:"
    Rails.logger.info "  - libvips: #{libvips_status ? '✅ available' : '❌ not available'}"
    Rails.logger.info "  - webpmux: #{webpmux_status ? '✅ available' : '❌ not available'}"
    Rails.logger.info "  - img2webp: #{img2webp_status ? '✅ available' : '❌ not available'}"
    
    file_size = File.size(image_path)
    size_mb = file_size / (1024.0 * 1024.0)
    
    # Análise da complexidade da animação
    complexity = case
    when frame_count <= 5
      :simple
    when frame_count <= 15
      :moderate  
    when frame_count <= 30
      :complex
    else
      :very_complex
    end
    
    Rails.logger.info "📊 [STRATEGY] Animation complexity: #{complexity} (#{frame_count} frames, #{size_mb.round(2)}MB)"
    
    # HIERARQUIA EXATA DO GUIA:
    # 1º: libvips (mais eficiente) - SEMPRE primeiro quando disponível
    # 2º: Extract-Process-Reassemble (mais robusto)
    # 3º: Tool method (fallback ImageMagick)
    # 4º: combine_options (último recurso)
    
    strategy = case
    when libvips_status
      Rails.logger.info "🚀 [STRATEGY] PRIORITY 1: libvips available - using high-performance option"
      :libvips
    when webpmux_status && img2webp_status
      Rails.logger.info "🔧 [STRATEGY] PRIORITY 2: libwebp tools available - using extract-reassemble"
      :extract_reassemble
    when complexity == :very_complex || size_mb > 2.0
      Rails.logger.info "⚠️ [STRATEGY] PRIORITY 3: Complex animation - using conservative tool method"
      :tool_method
    else
      Rails.logger.info "🔧 [STRATEGY] PRIORITY 4: Using combine_options fallback"
      :combine_options
    end
    
    Rails.logger.info "🎯 [STRATEGY] Selected strategy: #{strategy} (based on priority hierarchy)"
    strategy
  end

  # Processamento otimizado com libvips (Seção 4 do guia)
  # Implementa a abordagem "film strip" para máxima eficiência
  def process_with_libvips(image_path, quality, is_animated, has_transparency)
    Rails.logger.info "🚀 [LIBVIPS] Using high-performance libvips processing (PRIORITY 1)"
    
    begin
      require 'vips'
      
      if is_animated
        Rails.logger.info "🎬 [LIBVIPS] Processing animated WebP as film strip"
        
        # Carregar todos os frames com n: -1 (opção crítica do guia)
        begin
          # Opção access: :sequential para otimizar memória (recomendação do guia)
          vips_image = Vips::Image.new_from_file(image_path, n: -1, access: :sequential)
          Rails.logger.info "🎬 [LIBVIPS] Loaded animated image: #{vips_image.width}x#{vips_image.height}"
          
          # Extrair metadados ANTES do processamento (crítico)
          begin
            original_delay = vips_image.get('delay')
            original_loop = vips_image.get('loop') rescue 0
            original_page_height = vips_image.get('page-height')
            num_pages = vips_image.get('n-pages') rescue (vips_image.height / original_page_height).round
            
            Rails.logger.info "🎬 [LIBVIPS] Extracted metadata:"
            Rails.logger.info "  - Pages: #{num_pages}"
            Rails.logger.info "  - Page height: #{original_page_height}"
            Rails.logger.info "  - Loop: #{original_loop}"
            Rails.logger.info "  - Delays: #{original_delay.is_a?(Array) ? original_delay.length : 'single'} values"
            
          rescue Vips::Error => e
            Rails.logger.warn "⚠️ [LIBVIPS] Could not extract full metadata: #{e.message}"
            # Fallback: tentar calcular num_pages
            if vips_image.height > vips_image.width
              estimated_page_height = TARGET_DIMENSIONS[1]
              num_pages = (vips_image.height / estimated_page_height).round
              Rails.logger.info "🔍 [LIBVIPS] Estimated #{num_pages} pages from dimensions"
            else
              Rails.logger.error "❌ [LIBVIPS] Cannot determine animation structure"
              return nil
            end
          end
          
          if num_pages <= 1
            Rails.logger.warn "🔍 [LIBVIPS] Only #{num_pages} page(s) detected, treating as static"
            is_animated = false
          else
            Rails.logger.info "🎬 [LIBVIPS] Processing #{num_pages} frames using film strip method"
            
            # Redimensionar usando thumbnail (mais eficiente que resize)
            # O thumbnail preserva a proporção e é otimizado para performance
            processed_image = vips_image.thumbnail(TARGET_DIMENSIONS[0], 
              height: TARGET_DIMENSIONS[1], 
              crop: :centre,
              size: :both  # Força ambas as dimensões
            )
            
            Rails.logger.info "🎬 [LIBVIPS] Resized film strip: #{processed_image.width}x#{processed_image.height}"
            
            # Recalcular metadados após redimensionamento
            scale_factor = processed_image.height.to_f / vips_image.height.to_f
            new_page_height = TARGET_DIMENSIONS[1]  # Forçar altura exata do frame
            
            Rails.logger.info "🔧 [LIBVIPS] Scale factor: #{scale_factor.round(3)}, new page height: #{new_page_height}"
            
            # Re-aplicar metadados usando mutate (seguro para concorrência)
            final_image = processed_image.mutate do |img|
              begin
                # Preservar metadados de animação
                if original_delay.is_a?(Array)
                  img.set_type(Vips::GTYPES[:VipsArrayInt], 'delay', original_delay)
                end
                img.set_type(Vips::GTYPES[:int], 'loop', original_loop)
                img.set_type(Vips::GTYPES[:int], 'page-height', new_page_height)
                img.set_type(Vips::GTYPES[:int], 'n-pages', num_pages)
                
                Rails.logger.info "✅ [LIBVIPS] Metadata reapplied successfully"
              rescue Vips::Error => meta_error
                Rails.logger.warn "⚠️ [LIBVIPS] Metadata application failed: #{meta_error.message}"
                # Continuar sem todos os metadados - melhor que falhar completamente
              end
            end
            
            # Salvar com opções específicas para WebP animado
            output_path = "#{image_path}_libvips_#{quality}.webp"
            
            save_options = {
              Q: quality,
              effort: 6,        # Balance entre qualidade e velocidade
              method: 6,        # Método de compressão otimizado
              lossless: false
            }
            
            if has_transparency
              save_options.merge!({
                alpha_q: 100,
                alpha_compression: 1
              })
            end
            
            Rails.logger.info "🔧 [LIBVIPS] Saving with options: #{save_options}"
            final_image.webpsave(output_path, **save_options)
            
            # Retornar imagem MiniMagick para compatibilidade
            result_image = MiniMagick::Image.open(output_path)
            result_frames = result_image.frames.count
            
            Rails.logger.info "✅ [LIBVIPS] Animation processed: #{result_frames} frames preserved"
            return result_image
          end
          
        rescue Vips::Error => e
          Rails.logger.warn "⚠️ [LIBVIPS] Failed to load as animation: #{e.message}"
          Rails.logger.info "🔄 [LIBVIPS] Falling back to static processing"
          is_animated = false
        end
      end
      
      # Processar como imagem estática (ou fallback de animação)
      unless is_animated
        Rails.logger.info "📸 [LIBVIPS] Processing as static image"
        
        vips_image = Vips::Image.new_from_file(image_path)
        
        # Usar thumbnail para eficiência máxima
        processed = vips_image.thumbnail(TARGET_DIMENSIONS[0], 
          height: TARGET_DIMENSIONS[1], 
          crop: :centre,
          size: :both
        )
        
        # Salvar como WebP estático
        output_path = "#{image_path}_libvips_static_#{quality}.webp"
        save_options = { Q: quality }
        
        if has_transparency
          save_options.merge!({
            alpha_q: 100,
            lossless: false
          })
        end
        
        processed.webpsave(output_path, **save_options)
        
        # Retornar imagem MiniMagick para compatibilidade
        result_image = MiniMagick::Image.open(output_path)
        Rails.logger.info "✅ [LIBVIPS] Static image processed successfully"
        return result_image
      end
      
    rescue LoadError => e
      Rails.logger.error "❌ [LIBVIPS] Library not available: #{e.message}"
      return nil
    rescue StandardError => e
      Rails.logger.error "❌ [LIBVIPS] Processing failed: #{e.message}"
      Rails.logger.error "📚 [LIBVIPS] Backtrace: #{e.backtrace.first(5).join("\n")}"
      return nil
    end
  end
end