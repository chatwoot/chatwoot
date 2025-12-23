module LanguageServer
  module Protocol
    module Interface
      #
      # Delete file options
      #
      class DeleteFileOptions
        def initialize(recursive: nil, ignore_if_not_exists: nil)
          @attributes = {}

          @attributes[:recursive] = recursive if recursive
          @attributes[:ignoreIfNotExists] = ignore_if_not_exists if ignore_if_not_exists

          @attributes.freeze
        end

        #
        # Delete the content recursively if a folder is denoted.
        #
        # @return [boolean]
        def recursive
          attributes.fetch(:recursive)
        end

        #
        # Ignore the operation if the file doesn't exist.
        #
        # @return [boolean]
        def ignore_if_not_exists
          attributes.fetch(:ignoreIfNotExists)
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
