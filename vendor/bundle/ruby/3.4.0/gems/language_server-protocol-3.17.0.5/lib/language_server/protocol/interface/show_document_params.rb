module LanguageServer
  module Protocol
    module Interface
      #
      # Params to show a resource.
      #
      class ShowDocumentParams
        def initialize(uri:, external: nil, take_focus: nil, selection: nil)
          @attributes = {}

          @attributes[:uri] = uri
          @attributes[:external] = external if external
          @attributes[:takeFocus] = take_focus if take_focus
          @attributes[:selection] = selection if selection

          @attributes.freeze
        end

        #
        # The uri to show.
        #
        # @return [string]
        def uri
          attributes.fetch(:uri)
        end

        #
        # Indicates to show the resource in an external program.
        # To show, for example, `https://code.visualstudio.com/`
        # in the default WEB browser set `external` to `true`.
        #
        # @return [boolean]
        def external
          attributes.fetch(:external)
        end

        #
        # An optional property to indicate whether the editor
        # showing the document should take focus or not.
        # Clients might ignore this property if an external
        # program is started.
        #
        # @return [boolean]
        def take_focus
          attributes.fetch(:takeFocus)
        end

        #
        # An optional selection range if the document is a text
        # document. Clients might ignore the property if an
        # external program is started or the file is not a text
        # file.
        #
        # @return [Range]
        def selection
          attributes.fetch(:selection)
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
