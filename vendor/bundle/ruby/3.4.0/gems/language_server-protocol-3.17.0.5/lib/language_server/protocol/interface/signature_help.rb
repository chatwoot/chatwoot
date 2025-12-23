module LanguageServer
  module Protocol
    module Interface
      #
      # Signature help represents the signature of something
      # callable. There can be multiple signature but only one
      # active and only one active parameter.
      #
      class SignatureHelp
        def initialize(signatures:, active_signature: nil, active_parameter: nil)
          @attributes = {}

          @attributes[:signatures] = signatures
          @attributes[:activeSignature] = active_signature if active_signature
          @attributes[:activeParameter] = active_parameter if active_parameter

          @attributes.freeze
        end

        #
        # One or more signatures. If no signatures are available the signature help
        # request should return `null`.
        #
        # @return [SignatureInformation[]]
        def signatures
          attributes.fetch(:signatures)
        end

        #
        # The active signature. If omitted or the value lies outside the
        # range of `signatures` the value defaults to zero or is ignore if
        # the `SignatureHelp` as no signatures.
        #
        # Whenever possible implementors should make an active decision about
        # the active signature and shouldn't rely on a default value.
        #
        # In future version of the protocol this property might become
        # mandatory to better express this.
        #
        # @return [number]
        def active_signature
          attributes.fetch(:activeSignature)
        end

        #
        # The active parameter of the active signature. If omitted or the value
        # lies outside the range of `signatures[activeSignature].parameters`
        # defaults to 0 if the active signature has parameters. If
        # the active signature has no parameters it is ignored.
        # In future version of the protocol this property might become
        # mandatory to better express the active parameter if the
        # active signature does have any.
        #
        # @return [number]
        def active_parameter
          attributes.fetch(:activeParameter)
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
