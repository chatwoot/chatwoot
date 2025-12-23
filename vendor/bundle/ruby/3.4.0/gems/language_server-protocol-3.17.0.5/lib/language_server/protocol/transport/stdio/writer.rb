module LanguageServer
  module Protocol
    module Transport
      module Stdio
        class Writer < Io::Writer
          def initialize
            super STDOUT
          end
        end
      end
    end
  end
end
