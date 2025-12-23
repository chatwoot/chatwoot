module LanguageServer
  module Protocol
    module Interface
      #
      # Rename file options
      #
      class RenameFileOptions
        def initialize(overwrite: nil, ignore_if_exists: nil)
          @attributes = {}

          @attributes[:overwrite] = overwrite if overwrite
          @attributes[:ignoreIfExists] = ignore_if_exists if ignore_if_exists

          @attributes.freeze
        end

        #
        # Overwrite target if existing. Overwrite wins over `ignoreIfExists`
        #
        # @return [boolean]
        def overwrite
          attributes.fetch(:overwrite)
        end

        #
        # Ignores if target exists.
        #
        # @return [boolean]
        def ignore_if_exists
          attributes.fetch(:ignoreIfExists)
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
