module LanguageServer
  module Protocol
    module Interface
      class Command
        def initialize(title:, command:, arguments: nil)
          @attributes = {}

          @attributes[:title] = title
          @attributes[:command] = command
          @attributes[:arguments] = arguments if arguments

          @attributes.freeze
        end

        #
        # Title of the command, like `save`.
        #
        # @return [string]
        def title
          attributes.fetch(:title)
        end

        #
        # The identifier of the actual command handler.
        #
        # @return [string]
        def command
          attributes.fetch(:command)
        end

        #
        # Arguments that the command handler should be
        # invoked with.
        #
        # @return [LSPAny[]]
        def arguments
          attributes.fetch(:arguments)
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
