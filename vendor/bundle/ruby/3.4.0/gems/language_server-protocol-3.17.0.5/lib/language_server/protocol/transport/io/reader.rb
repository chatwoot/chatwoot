# frozen_string_literal: true

require "json"

module LanguageServer
  module Protocol
    module Transport
      module Io
        class Reader
          def initialize(io)
            @io = io
            io.binmode
          end

          def read(&block)
            while buffer = io.gets("\r\n\r\n")
              content_length = buffer.match(/Content-Length: (\d+)/i)[1].to_i
              message = io.read(content_length) or raise
              request = JSON.parse(message, symbolize_names: true)
              block.call(request)
            end
          end

          def close
            io.close
          end

          private

          attr_reader :io
        end
      end
    end
  end
end
