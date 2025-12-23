module LanguageServer
  module Protocol
    module Interface
      class WorkspaceFolder
        def initialize(uri:, name:)
          @attributes = {}

          @attributes[:uri] = uri
          @attributes[:name] = name

          @attributes.freeze
        end

        #
        # The associated URI for this workspace folder.
        #
        # @return [string]
        def uri
          attributes.fetch(:uri)
        end

        #
        # The name of the workspace folder. Used to refer to this
        # workspace folder in the user interface.
        #
        # @return [string]
        def name
          attributes.fetch(:name)
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
