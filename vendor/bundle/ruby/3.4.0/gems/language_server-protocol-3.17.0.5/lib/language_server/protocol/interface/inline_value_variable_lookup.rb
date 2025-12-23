module LanguageServer
  module Protocol
    module Interface
      #
      # Provide inline value through a variable lookup.
      #
      # If only a range is specified, the variable name will be extracted from
      # the underlying document.
      #
      # An optional variable name can be used to override the extracted name.
      #
      class InlineValueVariableLookup
        def initialize(range:, variable_name: nil, case_sensitive_lookup:)
          @attributes = {}

          @attributes[:range] = range
          @attributes[:variableName] = variable_name if variable_name
          @attributes[:caseSensitiveLookup] = case_sensitive_lookup

          @attributes.freeze
        end

        #
        # The document range for which the inline value applies.
        # The range is used to extract the variable name from the underlying
        # document.
        #
        # @return [Range]
        def range
          attributes.fetch(:range)
        end

        #
        # If specified the name of the variable to look up.
        #
        # @return [string]
        def variable_name
          attributes.fetch(:variableName)
        end

        #
        # How to perform the lookup.
        #
        # @return [boolean]
        def case_sensitive_lookup
          attributes.fetch(:caseSensitiveLookup)
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
