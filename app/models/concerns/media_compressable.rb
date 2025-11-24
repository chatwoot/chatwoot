module MediaCompressable
  extend ActiveSupport::Concern

  # Configurações de compressão
  MAX_VIDEO_SIZE_MB = ENV.fetch('VIDEO_COMPRESSION_THRESHOLD_MB', 40).to_i
  MAX_AUDIO_SIZE_MB = ENV.fetch('AUDIO_COMPRESSION_THRESHOLD_MB', 20).to_i

  # Qualidade de compressão
  VIDEO_COMPRESSION_CRF = ENV.fetch('VIDEO_COMPRESSION_CRF', 28).to_i
  VIDEO_COMPRESSION_PRESET = ENV.fetch('VIDEO_COMPRESSION_PRESET', 'slow')
  AUDIO_COMPRESSION_BITRATE = ENV.fetch('AUDIO_COMPRESSION_BITRATE', '128k')

  included do
    before_commit :compress_media_if_needed, on: :create, if: :should_compress_media?
  end

  def should_compress_media?
    return false unless file.attached?
    return false unless video? || audio?

    if video?
      file.byte_size > MAX_VIDEO_SIZE_MB.megabytes
    elsif audio?
      file.byte_size > MAX_AUDIO_SIZE_MB.megabytes
    else
      false
    end
  end

  private

  def compress_media_if_needed
    return unless should_compress_media?

    media_type = video? ? 'video' : 'audio'
    original_size_mb = file.byte_size / 1.megabyte

    Rails.logger.info "Compressing #{media_type} attachment #{id} (#{original_size_mb}MB)"

    compressed_file = if video?
                        compress_video_sync
                      else
                        compress_audio_sync
                      end

    if compressed_file
      # Substituir o arquivo original pelo comprimido
      content_type = video? ? 'video/mp4' : 'audio/mpeg'
      file.attach(
        io: compressed_file,
        filename: file.filename,
        content_type: content_type
      )

      new_size_mb = file.byte_size / 1.megabyte
      compression_ratio = ((1 - (new_size_mb.to_f / original_size_mb)) * 100).round(1)
      Rails.logger.info "#{media_type.capitalize} compressed: #{original_size_mb}MB → #{new_size_mb}MB (#{compression_ratio}% reduction)"
    end
  rescue StandardError => e
    Rails.logger.error "Error compressing #{media_type} #{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Não falhar o save se a compressão falhar
  end

  def compress_video_sync
    require 'streamio-ffmpeg'

    temp_input = Tempfile.new(['input', File.extname(file.filename.to_s)])
    temp_output = Tempfile.new(['output', '.mp4'])

    begin
      # Download do arquivo
      temp_input.binmode
      temp_input.write(file.download)
      temp_input.rewind

      # Comprimir com FFmpeg
      movie = FFMPEG::Movie.new(temp_input.path)

      movie.transcode(
        temp_output.path,
        {
          video_codec: 'libx264',
          video_bitrate: '1000k',
          audio_codec: 'aac',
          audio_bitrate: AUDIO_COMPRESSION_BITRATE,
          custom: [
            '-preset', VIDEO_COMPRESSION_PRESET,
            '-crf', VIDEO_COMPRESSION_CRF.to_s,
            '-movflags', 'faststart' # Para streaming web
          ]
        }
      )

      temp_output.rewind
      temp_output
    ensure
      temp_input.close
      temp_input.unlink
    end
  end

  def compress_audio_sync
    require 'streamio-ffmpeg'

    temp_input = Tempfile.new(['input', File.extname(file.filename.to_s)])
    temp_output = Tempfile.new(['output', '.mp3'])

    begin
      # Download do arquivo
      temp_input.binmode
      temp_input.write(file.download)
      temp_input.rewind

      # Comprimir áudio com FFmpeg
      movie = FFMPEG::Movie.new(temp_input.path)

      # Para áudio, converter para MP3 com bitrate configurável
      movie.transcode(
        temp_output.path,
        {
          audio_codec: 'libmp3lame',
          audio_bitrate: AUDIO_COMPRESSION_BITRATE,
          audio_sample_rate: 44100, # Qualidade padrão
          custom: [
            '-q:a', '2' # Qualidade VBR (0-9, menor = melhor)
          ]
        }
      )

      temp_output.rewind
      temp_output
    ensure
      temp_input.close
      temp_input.unlink
    end
  end
end

