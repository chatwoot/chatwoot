# frozen_string_literal: true
require 'sprockets/encoding_utils'
require 'sprockets/http_utils'
require 'sprockets/utils'

module Sprockets
  module Mime
    include HTTPUtils, Utils

    # Public: Mapping of MIME type Strings to properties Hash.
    #
    # key   - MIME Type String
    # value - Hash
    #   extensions - Array of extnames
    #   charset    - Default Encoding or function to detect encoding
    #
    # Returns Hash.
    def mime_types
      config[:mime_types]
    end

    # Internal: Mapping of MIME extension Strings to MIME type Strings.
    #
    # Used for internal fast lookup purposes.
    #
    # Examples:
    #
    #   mime_exts['.js'] #=> 'application/javascript'
    #
    # key   - MIME extension String
    # value - MIME Type String
    #
    # Returns Hash.
    def mime_exts
      config[:mime_exts]
    end

    # Public: Register a new mime type.
    #
    # mime_type  - String MIME Type
    # extensions - Array of String extnames
    # charset    - Proc/Method that detects the charset of a file.
    #              See EncodingUtils.
    #
    # Returns nothing.
    def register_mime_type(mime_type, extensions: [], charset: nil)
      extnames = Array(extensions)

      charset ||= :default if mime_type.start_with?('text/')
      charset = EncodingUtils::CHARSET_DETECT[charset] if charset.is_a?(Symbol)

      self.config = hash_reassoc(config, :mime_exts) do |mime_exts|
        extnames.each do |extname|
          mime_exts[extname] = mime_type
        end
        mime_exts
      end

      self.config = hash_reassoc(config, :mime_types) do |mime_types|
        type = { extensions: extnames }
        type[:charset] = charset if charset
        mime_types.merge(mime_type => type)
      end
    end

    # Internal: Get detecter function for MIME type.
    #
    # mime_type - String MIME type
    #
    # Returns Proc detector or nil if none is available.
    def mime_type_charset_detecter(mime_type)
      if type = config[:mime_types][mime_type]
        if detect = type[:charset]
          return detect
        end
      end
    end

    # Public: Read file on disk with MIME type specific encoding.
    #
    # filename     - String path
    # content_type - String MIME type
    #
    # Returns String file contents transcoded to UTF-8 or in its external
    # encoding.
    def read_file(filename, content_type = nil)
      data = File.binread(filename)

      if detect = mime_type_charset_detecter(content_type)
        detect.call(data).encode(Encoding::UTF_8, universal_newline: true)
      else
        data
      end
    end
  end
end
