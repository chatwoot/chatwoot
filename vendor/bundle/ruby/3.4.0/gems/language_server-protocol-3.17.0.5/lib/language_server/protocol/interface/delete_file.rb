module LanguageServer
  module Protocol
    module Interface
      #
      # Delete file operation
      #
      class DeleteFile
        def initialize(kind:, uri:, options: nil, annotation_id: nil)
          @attributes = {}

          @attributes[:kind] = kind
          @attributes[:uri] = uri
          @attributes[:options] = options if options
          @attributes[:annotationId] = annotation_id if annotation_id

          @attributes.freeze
        end

        #
        # A delete
        #
        # @return ["delete"]
        def kind
          attributes.fetch(:kind)
        end

        #
        # The file to delete.
        #
        # @return [string]
        def uri
          attributes.fetch(:uri)
        end

        #
        # Delete options.
        #
        # @return [DeleteFileOptions]
        def options
          attributes.fetch(:options)
        end

        #
        # An optional annotation identifier describing the operation.
        #
        # @return [string]
        def annotation_id
          attributes.fetch(:annotationId)
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
