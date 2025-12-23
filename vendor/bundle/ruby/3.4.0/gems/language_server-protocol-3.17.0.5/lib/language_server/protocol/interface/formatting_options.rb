module LanguageServer
  module Protocol
    module Interface
      #
      # Value-object describing what options formatting should use.
      #
      class FormattingOptions
        def initialize(tab_size:, insert_spaces:, trim_trailing_whitespace: nil, insert_final_newline: nil, trim_final_newlines: nil)
          @attributes = {}

          @attributes[:tabSize] = tab_size
          @attributes[:insertSpaces] = insert_spaces
          @attributes[:trimTrailingWhitespace] = trim_trailing_whitespace if trim_trailing_whitespace
          @attributes[:insertFinalNewline] = insert_final_newline if insert_final_newline
          @attributes[:trimFinalNewlines] = trim_final_newlines if trim_final_newlines

          @attributes.freeze
        end

        #
        # Size of a tab in spaces.
        #
        # @return [number]
        def tab_size
          attributes.fetch(:tabSize)
        end

        #
        # Prefer spaces over tabs.
        #
        # @return [boolean]
        def insert_spaces
          attributes.fetch(:insertSpaces)
        end

        #
        # Trim trailing whitespace on a line.
        #
        # @return [boolean]
        def trim_trailing_whitespace
          attributes.fetch(:trimTrailingWhitespace)
        end

        #
        # Insert a newline character at the end of the file if one does not exist.
        #
        # @return [boolean]
        def insert_final_newline
          attributes.fetch(:insertFinalNewline)
        end

        #
        # Trim all newlines after the final newline at the end of the file.
        #
        # @return [boolean]
        def trim_final_newlines
          attributes.fetch(:trimFinalNewlines)
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
