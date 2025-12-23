# frozen_string_literal: true

module Sentry
  class Attachment
    PathNotFoundError = Class.new(StandardError)

    attr_reader :bytes, :filename, :path, :content_type

    def initialize(bytes: nil, filename: nil, content_type: nil, path: nil)
      @bytes = bytes
      @filename = infer_filename(filename, path)
      @path = path
      @content_type = content_type
    end

    def to_envelope_headers
      { type: 'attachment', filename: filename, content_type: content_type, length: payload.bytesize }
    end

    def payload
      @payload ||= if bytes
        bytes
      else
        File.binread(path)
      end
    rescue Errno::ENOENT
      raise PathNotFoundError, "Failed to read attachment file, file not found: #{path}"
    end

    private

    def infer_filename(filename, path)
      return filename if filename

      if path
        File.basename(path)
      else
        raise ArgumentError, "filename or path is required"
      end
    end
  end
end
