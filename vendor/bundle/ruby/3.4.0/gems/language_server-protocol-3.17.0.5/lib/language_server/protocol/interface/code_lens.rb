module LanguageServer
  module Protocol
    module Interface
      #
      # A code lens represents a command that should be shown along with
      # source text, like the number of references, a way to run tests, etc.
      #
      # A code lens is _unresolved_ when no command is associated to it. For
      # performance reasons the creation of a code lens and resolving should be done
      # in two stages.
      #
      class CodeLens
        def initialize(range:, command: nil, data: nil)
          @attributes = {}

          @attributes[:range] = range
          @attributes[:command] = command if command
          @attributes[:data] = data if data

          @attributes.freeze
        end

        #
        # The range in which this code lens is valid. Should only span a single
        # line.
        #
        # @return [Range]
        def range
          attributes.fetch(:range)
        end

        #
        # The command this code lens represents.
        #
        # @return [Command]
        def command
          attributes.fetch(:command)
        end

        #
        # A data entry field that is preserved on a code lens item between
        # a code lens and a code lens resolve request.
        #
        # @return [LSPAny]
        def data
          attributes.fetch(:data)
        end

        attr_reader :attributes

        def to_hash
          attributes
        end

        def to_json(*args)
          to_hash.to_json(*args)
        end
      end
    end
  end
end
