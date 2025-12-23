module LanguageServer
  module Protocol
    module Interface
      #
      # Options to create a file.
      #
      class CreateFileOptions
        def initialize(overwrite: nil, ignore_if_exists: nil)
          @attributes = {}

          @attributes[:overwrite] = overwrite if overwrite
          @attributes[:ignoreIfExists] = ignore_if_exists if ignore_if_exists

          @attributes.freeze
        end

        #
        # Overwrite existing file. Overwrite wins over `ignoreIfExists`
        #
        # @return [boolean]
        def overwrite
          attributes.fetch(:overwrite)
        end

        #
        # Ignore if exists.
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
