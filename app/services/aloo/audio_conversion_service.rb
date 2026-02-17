# frozen_string_literal: true

module Aloo
  class AudioConversionService
    SUPPORTED_OUTPUT_FORMATS = %w[ogg mp3 wav].freeze
    WHATSAPP_FORMAT = 'ogg'
    FFMPEG_TIMEOUT = 30

    class ConversionError < StandardError; end
    class FfmpegNotFoundError < ConversionError; end

    attr_reader :input_path, :output_format

    def initialize(input_path, output_format: WHATSAPP_FORMAT)
      @input_path = input_path
      @output_format = output_format
      validate!
    end

    def convert
      ensure_ffmpeg_available!

      output_path = generate_output_path
      execute_ffmpeg(output_path)
      output_path
    rescue StandardError => e
      Rails.logger.error("[Aloo::AudioConversion] Failed: #{e.message}")
      raise ConversionError, "Audio conversion failed: #{e.message}"
    end

    # Convenience method for WhatsApp voice notes
    def self.convert_to_whatsapp(input_path)
      new(input_path, output_format: WHATSAPP_FORMAT).convert
    end

    # Convert from binary data instead of file path
    def self.convert_data_to_whatsapp(audio_data, original_format: 'mp3')
      temp_input = Tempfile.new(['aloo_input', ".#{original_format}"], binmode: true)
      temp_input.write(audio_data)
      temp_input.close

      output_path = new(temp_input.path, output_format: WHATSAPP_FORMAT).convert
      output_path
    ensure
      temp_input&.unlink
    end

    private

    def validate!
      raise ArgumentError, "Input file not found: #{input_path}" unless File.exist?(input_path)
      raise ArgumentError, "Unsupported format: #{output_format}" unless SUPPORTED_OUTPUT_FORMATS.include?(output_format)
    end

    def ensure_ffmpeg_available!
      return if system('which ffmpeg > /dev/null 2>&1')

      raise FfmpegNotFoundError, 'FFmpeg is not installed. Please install FFmpeg to enable audio conversion.'
    end

    def generate_output_path
      dir = Rails.root.join('tmp/aloo_audio')
      FileUtils.mkdir_p(dir)

      basename = File.basename(input_path, '.*')
      timestamp = Time.current.to_i
      File.join(dir, "#{basename}_#{timestamp}.#{output_format}")
    end

    def execute_ffmpeg(output_path)
      command = build_ffmpeg_command(output_path)

      Rails.logger.debug { "[Aloo::AudioConversion] Running: #{command.join(' ')}" }

      Timeout.timeout(FFMPEG_TIMEOUT) do
        _, stderr, status = Open3.capture3(*command)

        unless status.success?
          Rails.logger.error("[Aloo::AudioConversion] FFmpeg stderr: #{stderr}")
          raise ConversionError, "FFmpeg failed: #{stderr.truncate(200)}"
        end
      end

      raise ConversionError, 'Output file not created' unless File.exist?(output_path)

      output_path
    end

    def build_ffmpeg_command(output_path)
      base_cmd = ['ffmpeg', '-y', '-i', input_path, '-loglevel', 'error']

      case output_format
      when 'ogg'
        # Opus codec for WhatsApp voice notes
        # Using libopus for better quality and smaller file size
        base_cmd + ['-c:a', 'libopus', '-ac', '1', '-ar', '48000', '-b:a', '64k', '-vbr', 'on', '-application', 'voip', output_path]
      when 'mp3'
        base_cmd + ['-c:a', 'libmp3lame', '-b:a', '128k', output_path]
      when 'wav'
        base_cmd + ['-c:a', 'pcm_s16le', output_path]
      else
        raise ConversionError, "Unknown format: #{output_format}"
      end
    end
  end
end
