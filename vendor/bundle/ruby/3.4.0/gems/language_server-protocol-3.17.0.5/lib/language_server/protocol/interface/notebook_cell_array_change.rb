module LanguageServer
  module Protocol
    module Interface
      #
      # A change describing how to move a `NotebookCell`
      # array from state S to S'.
      #
      class NotebookCellArrayChange
        def initialize(start:, delete_count:, cells: nil)
          @attributes = {}

          @attributes[:start] = start
          @attributes[:deleteCount] = delete_count
          @attributes[:cells] = cells if cells

          @attributes.freeze
        end

        #
        # The start offset of the cell that changed.
        #
        # @return [number]
        def start
          attributes.fetch(:start)
        end

        #
        # The deleted cells
        #
        # @return [number]
        def delete_count
          attributes.fetch(:deleteCount)
        end

        #
        # The new cells, if any
        #
        # @return [NotebookCell[]]
        def cells
          attributes.fetch(:cells)
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
