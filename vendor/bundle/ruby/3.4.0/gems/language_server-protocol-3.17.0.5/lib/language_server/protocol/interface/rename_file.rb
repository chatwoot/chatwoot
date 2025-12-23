module LanguageServer
  module Protocol
    module Interface
      #
      # Rename file operation
      #
      class RenameFile
        def initialize(kind:, old_uri:, new_uri:, options: nil, annotation_id: nil)
          @attributes = {}

          @attributes[:kind] = kind
          @attributes[:oldUri] = old_uri
          @attributes[:newUri] = new_uri
          @attributes[:options] = options if options
          @attributes[:annotationId] = annotation_id if annotation_id

          @attributes.freeze
        end

        #
        # A rename
        #
        # @return ["rename"]
        def kind
          attributes.fetch(:kind)
        end

        #
        # The old (existing) location.
        #
        # @return [string]
        def old_uri
          attributes.fetch(:oldUri)
        end

        #
        # The new location.
        #
        # @return [string]
        def new_uri
          attributes.fetch(:newUri)
        end

        #
        # Rename options.
        #
        # @return [RenameFileOptions]
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
