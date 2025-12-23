# frozen_string_literal: true

module RubyLLM
  # A class representing a file attachment.
  class Attachment
    attr_reader :source, :filename, :mime_type

    def initialize(source, filename: nil)
      @source = source
      if url?
        @source = URI source
        @filename = filename || File.basename(@source.path).to_s
      elsif path?
        @source = Pathname.new source
        @filename = filename || @source.basename.to_s
      elsif active_storage?
        @filename = filename || extract_filename_from_active_storage
      else
        @filename = filename
      end

      determine_mime_type
    end

    def url?
      @source.is_a?(URI) || (@source.is_a?(String) && @source.match?(%r{^https?://}))
    end

    def path?
      @source.is_a?(Pathname) || (@source.is_a?(String) && !url?)
    end

    def io_like?
      @source.respond_to?(:read) && !path? && !active_storage?
    end

    def active_storage?
      return false unless defined?(ActiveStorage)

      @source.is_a?(ActiveStorage::Blob) ||
        @source.is_a?(ActiveStorage::Attached::One) ||
        @source.is_a?(ActiveStorage::Attached::Many)
    end

    def content
      return @content if defined?(@content) && !@content.nil?

      if url?
        fetch_content
      elsif path?
        load_content_from_path
      elsif active_storage?
        load_content_from_active_storage
      elsif io_like?
        load_content_from_io
      else
        RubyLLM.logger.warn "Source is neither a URL, path, ActiveStorage, nor IO-like: #{@source.class}"
        nil
      end

      @content
    end

    def encoded
      Base64.strict_encode64(content)
    end

    def for_llm
      case type
      when :text
        "<file name='#{filename}' mime_type='#{mime_type}'>#{content}</file>"
      else
        "data:#{mime_type};base64,#{encoded}"
      end
    end

    def type
      return :image if image?
      return :video if video?
      return :audio if audio?
      return :pdf if pdf?
      return :text if text?

      :unknown
    end

    def image?
      RubyLLM::MimeType.image? mime_type
    end

    def video?
      RubyLLM::MimeType.video? mime_type
    end

    def audio?
      RubyLLM::MimeType.audio? mime_type
    end

    def format
      case mime_type
      when 'audio/mpeg'
        'mp3'
      when 'audio/wav', 'audio/wave', 'audio/x-wav'
        'wav'
      else
        mime_type.split('/').last
      end
    end

    def pdf?
      RubyLLM::MimeType.pdf? mime_type
    end

    def text?
      RubyLLM::MimeType.text? mime_type
    end

    def to_h
      { type: type, source: @source }
    end

    private

    def determine_mime_type
      return @mime_type = active_storage_content_type if active_storage? && active_storage_content_type.present?

      @mime_type = RubyLLM::MimeType.for(url? ? nil : @source, name: @filename)
      @mime_type = RubyLLM::MimeType.for(content) if @mime_type == 'application/octet-stream'
      @mime_type = 'audio/wav' if @mime_type == 'audio/x-wav' # Normalize WAV type
    end

    def fetch_content
      response = Connection.basic.get @source.to_s
      @content = response.body
    end

    def load_content_from_path
      @content = File.read(@source)
    end

    def load_content_from_io
      @source.rewind if @source.respond_to? :rewind
      @content = @source.read
    end

    def load_content_from_active_storage
      return unless defined?(ActiveStorage)

      @content = case @source
                 when ActiveStorage::Blob
                   @source.download
                 when ActiveStorage::Attached::One
                   @source.blob&.download
                 when ActiveStorage::Attached::Many
                   # For multiple attachments, just take the first one
                   # This maintains the single-attachment interface
                   @source.blobs.first&.download
                 end
    end

    def extract_filename_from_active_storage # rubocop:disable Metrics/PerceivedComplexity
      return 'attachment' unless defined?(ActiveStorage)

      case @source
      when ActiveStorage::Blob
        @source.filename.to_s
      when ActiveStorage::Attached::One
        @source.blob&.filename&.to_s || 'attachment'
      when ActiveStorage::Attached::Many
        @source.blobs.first&.filename&.to_s || 'attachment'
      else
        'attachment'
      end
    end

    def active_storage_content_type
      return unless defined?(ActiveStorage)

      case @source
      when ActiveStorage::Blob
        @source.content_type
      when ActiveStorage::Attached::One
        @source.blob&.content_type
      when ActiveStorage::Attached::Many
        @source.blobs.first&.content_type
      end
    end
  end
end
