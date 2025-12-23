module LanguageServer
  module Protocol
    module Interface
      #
      # Matching options for the file operation pattern.
      #
      class FileOperationPatternOptions
        def initialize(ignore_case: nil)
          @attributes = {}

          @attributes[:ignoreCase] = ignore_case if ignore_case

          @attributes.freeze
        end

        #
        # The pattern should be matched ignoring casing.
        #
        # @return [boolean]
        def ignore_case
          attributes.fetch(:ignoreCase)
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
