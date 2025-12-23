module LanguageServer
  module Protocol
    module Interface
      #
      # Execute command registration options.
      #
      class ExecuteCommandRegistrationOptions
        def initialize(work_done_progress: nil, commands:)
          @attributes = {}

          @attributes[:workDoneProgress] = work_done_progress if work_done_progress
          @attributes[:commands] = commands

          @attributes.freeze
        end

        # @return [boolean]
        def work_done_progress
          attributes.fetch(:workDoneProgress)
        end

        #
        # The commands to be executed on the server
        #
        # @return [string[]]
        def commands
          attributes.fetch(:commands)
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
