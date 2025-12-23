# frozen_string_literal: true

module HTTParty
  # Decompresses the response body based on the Content-Encoding header.
  #
  # Net::HTTP automatically decompresses Content-Encoding values "gzip" and "deflate".
  # This class will handle "br" (Brotli) and "compress" (LZW) if the requisite
  # gems are installed. Otherwise, it returns nil if the body data cannot be
  # decompressed.
  #
  # @abstract Read the HTTP Compression section for more information.
  class Decompressor

    # "gzip" and "deflate" are handled by Net::HTTP
    # hence they do not need to be handled by HTTParty
    SupportedEncodings = {
      'none'     => :none,
      'identity' => :none,
      'br'       => :brotli,
      'compress' => :lzw,
      'zstd'     => :zstd
    }.freeze

    # The response body of the request
    # @return [String]
    attr_reader :body

    # The Content-Encoding algorithm used to encode the body
    # @return [Symbol] e.g. :gzip
    attr_reader :encoding

    # @param [String] body - the response body of the request
    # @param [Symbol] encoding - the Content-Encoding algorithm used to encode the body
    def initialize(body, encoding)
      @body = body
      @encoding = encoding
    end

    # Perform decompression on the response body
    # @return [String] the decompressed body
    # @return [nil] when the response body is nil or cannot decompressed
    def decompress
      return nil if body.nil?
      return body if encoding.nil? || encoding.strip.empty?

      if supports_encoding?
        decompress_supported_encoding
      else
        nil
      end
    end

    protected

    def supports_encoding?
      SupportedEncodings.keys.include?(encoding)
    end

    def decompress_supported_encoding
      method = SupportedEncodings[encoding]
      if respond_to?(method, true)
        send(method)
      else
        raise NotImplementedError, "#{self.class.name} has not implemented a decompression method for #{encoding.inspect} encoding."
      end
    end

    def none
      body
    end

    def brotli
      return nil unless defined?(::Brotli)
      begin
        ::Brotli.inflate(body)
      rescue StandardError
        nil
      end
    end

    def lzw
      begin
        if defined?(::LZWS::String)
          ::LZWS::String.decompress(body)
        elsif defined?(::LZW::Simple)
          ::LZW::Simple.new.decompress(body)
        end
      rescue StandardError
        nil
      end
    end

    def zstd
      return nil unless defined?(::Zstd)
      begin
        ::Zstd.decompress(body)
      rescue StandardError
        nil
      end
    end
  end
end
