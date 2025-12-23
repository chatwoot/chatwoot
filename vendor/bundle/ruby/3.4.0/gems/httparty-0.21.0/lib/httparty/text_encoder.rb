# frozen_string_literal: true

module HTTParty
  class TextEncoder
    attr_reader :text, :content_type, :assume_utf16_is_big_endian

    def initialize(text, assume_utf16_is_big_endian: true, content_type: nil)
      @text = +text
      @content_type = content_type
      @assume_utf16_is_big_endian = assume_utf16_is_big_endian
    end

    def call
      if can_encode?
        encoded_text
      else
        text
      end
    end

    private

    def can_encode?
      ''.respond_to?(:encoding) && charset
    end

    def encoded_text
      if 'utf-16'.casecmp(charset) == 0
        encode_utf_16
      else
        encode_with_ruby_encoding
      end
    end

    def encode_utf_16
      if text.bytesize >= 2
        if text.getbyte(0) == 0xFF && text.getbyte(1) == 0xFE
          return text.force_encoding('UTF-16LE')
        elsif text.getbyte(0) == 0xFE && text.getbyte(1) == 0xFF
          return text.force_encoding('UTF-16BE')
        end
      end

      if assume_utf16_is_big_endian # option
        text.force_encoding('UTF-16BE')
      else
        text.force_encoding('UTF-16LE')
      end
    end

    def encode_with_ruby_encoding
      # NOTE: This will raise an argument error if the
      # charset does not exist
      encoding = Encoding.find(charset)
      text.force_encoding(encoding.to_s)
    rescue ArgumentError
      text
    end

    def charset
      return nil if content_type.nil?

      if (matchdata = content_type.match(/;\s*charset\s*=\s*([^=,;"\s]+)/i))
        return matchdata.captures.first
      end

      if (matchdata = content_type.match(/;\s*charset\s*=\s*"((\\.|[^\\"])+)"/i))
        return matchdata.captures.first.gsub(/\\(.)/, '\1')
      end
    end
  end
end
