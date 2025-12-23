module LanguageServer
  module Protocol
    module Transport
      module Io
        class Writer
          attr_reader :io

          def initialize(io)
            @io = io
            io.binmode
          end

          def write(response)
            response_str = JSON.generate(response.merge(
              jsonrpc: "2.0"
            ))

            headers = {
              "Content-Length" => response_str.bytesize
            }

            headers.each do |k, v|
              io.print "#{k}: #{v}\r\n"
            end

            io.print "\r\n"

            io.print response_str
            io.flush
          end

          def close
            io.close
          end
        end
      end
    end
  end
end
