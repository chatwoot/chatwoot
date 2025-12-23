module LanguageServer
  module Protocol
    module Interface
      #
      # A special text edit to provide an insert and a replace operation.
      #
      class InsertReplaceEdit
        def initialize(new_text:, insert:, replace:)
          @attributes = {}

          @attributes[:newText] = new_text
          @attributes[:insert] = insert
          @attributes[:replace] = replace

          @attributes.freeze
        end

        #
        # The string to be inserted.
        #
        # @return [string]
        def new_text
          attributes.fetch(:newText)
        end

        #
        # The range if the insert is requested
        #
        # @return [Range]
        def insert
          attributes.fetch(:insert)
        end

        #
        # The range if the replace is requested.
        #
        # @return [Range]
        def replace
          attributes.fetch(:replace)
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
