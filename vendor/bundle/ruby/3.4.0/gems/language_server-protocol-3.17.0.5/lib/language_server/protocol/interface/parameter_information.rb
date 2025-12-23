module LanguageServer
  module Protocol
    module Interface
      #
      # Represents a parameter of a callable-signature. A parameter can
      # have a label and a doc-comment.
      #
      class ParameterInformation
        def initialize(label:, documentation: nil)
          @attributes = {}

          @attributes[:label] = label
          @attributes[:documentation] = documentation if documentation

          @attributes.freeze
        end

        #
        # The label of this parameter information.
        #
        # Either a string or an inclusive start and exclusive end offsets within
        # its containing signature label. (see SignatureInformation.label). The
        # offsets are based on a UTF-16 string representation as `Position` and
        # `Range` does.
        #
        # *Note*: a label of type string should be a substring of its containing
        # signature label. Its intended use case is to highlight the parameter
        # label part in the `SignatureInformation.label`.
        #
        # @return [string | [number, number]]
        def label
          attributes.fetch(:label)
        end

        #
        # The human-readable doc-comment of this parameter. Will be shown
        # in the UI but can be omitted.
        #
        # @return [string | MarkupContent]
        def documentation
          attributes.fetch(:documentation)
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
