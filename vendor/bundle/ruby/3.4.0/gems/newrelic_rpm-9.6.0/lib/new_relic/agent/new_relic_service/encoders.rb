# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'base64'
require 'json'
require 'stringio'
require 'zlib'

module NewRelic
  module Agent
    class NewRelicService
      module Encoders
        module Identity
          def self.encode(data, opts = nil)
            data
          end
        end

        module Compressed
          module Deflate
            def self.encode(data, opts = nil)
              Zlib::Deflate.deflate(data, Zlib::DEFAULT_COMPRESSION)
            end
          end

          module Gzip
            BINARY = 'BINARY'.freeze

            def self.encode(data, opts = nil)
              output = StringIO.new
              output.set_encoding(BINARY)
              gz = Zlib::GzipWriter.new(output, Zlib::DEFAULT_COMPRESSION, Zlib::DEFAULT_STRATEGY)
              gz.write(data)
              gz.close
              output.rewind
              output.string
            end
          end
        end

        module Base64CompressedJSON
          def self.encode(data, opts = {})
            if !opts[:skip_normalization] && Agent.config[:normalize_json_string_encodings]
              data = NewRelic::Agent::EncodingNormalizer.normalize_object(data)
            end
            json = ::JSON.dump(data)
            Base64.encode64(Compressed::Deflate.encode(json))
          end
        end
      end
    end
  end
end
