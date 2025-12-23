# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

module ElasticAPM
  module Transport
    class Connection
      # @api private
      class ProxyPipe
        def initialize(enc = nil, compress: true)
          rd, wr = IO.pipe(enc)

          @read = rd
          @write = Write.new(wr, compress: compress)

          # Http.rb<4 calls rewind on the request bodies, but IO::Pipe raises
          # ~mikker
          return if HTTP::VERSION.to_i >= 4
          def rd.rewind; end
        end

        attr_reader :read, :write

        # @api private
        class Write
          include Logging

          def initialize(io, compress: true)
            @io = io
            @compress = compress
            @bytes_sent = Concurrent::AtomicFixnum.new(0)
            @config = ElasticAPM.agent&.config # this is silly, fix Logging

            return unless compress
            enable_compression!
            ObjectSpace.define_finalizer(self, self.class.finalize(@io))
          end

          def self.finalize(io)
            proc { io.close }
          end

          attr_reader :io

          def enable_compression!
            io.binmode
            @io = Zlib::GzipWriter.new(io)
          end

          def close
            io.close
          end

          def closed?
            io.closed?
          end

          def write(str)
            io.puts(str).tap do
              @bytes_sent.update do |curr|
                @compress ? io.tell : curr + str.bytesize
              end
            end
          end

          def bytes_sent
            @bytes_sent.value
          end
        end

        def self.pipe(**args)
          pipe = new(**args)
          [pipe.read, pipe.write]
        end
      end
    end
  end
end
