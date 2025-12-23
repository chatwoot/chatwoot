module LanguageServer
  module Protocol
    module Interface
      class PublishDiagnosticsClientCapabilities
        def initialize(related_information: nil, tag_support: nil, version_support: nil, code_description_support: nil, data_support: nil)
          @attributes = {}

          @attributes[:relatedInformation] = related_information if related_information
          @attributes[:tagSupport] = tag_support if tag_support
          @attributes[:versionSupport] = version_support if version_support
          @attributes[:codeDescriptionSupport] = code_description_support if code_description_support
          @attributes[:dataSupport] = data_support if data_support

          @attributes.freeze
        end

        #
        # Whether the clients accepts diagnostics with related information.
        #
        # @return [boolean]
        def related_information
          attributes.fetch(:relatedInformation)
        end

        #
        # Client supports the tag property to provide meta data about a diagnostic.
        # Clients supporting tags have to handle unknown tags gracefully.
        #
        # @return [{ valueSet: DiagnosticTag[]; }]
        def tag_support
          attributes.fetch(:tagSupport)
        end

        #
        # Whether the client interprets the version property of the
        # `textDocument/publishDiagnostics` notification's parameter.
        #
        # @return [boolean]
        def version_support
          attributes.fetch(:versionSupport)
        end

        #
        # Client supports a codeDescription property
        #
        # @return [boolean]
        def code_description_support
          attributes.fetch(:codeDescriptionSupport)
        end

        #
        # Whether code action supports the `data` property which is
        # preserved between a `textDocument/publishDiagnostics` and
        # `textDocument/codeAction` request.
        #
        # @return [boolean]
        def data_support
          attributes.fetch(:dataSupport)
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
