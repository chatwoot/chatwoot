module LanguageServer
  module Protocol
    module Interface
      class FileSystemWatcher
        def initialize(glob_pattern:, kind: nil)
          @attributes = {}

          @attributes[:globPattern] = glob_pattern
          @attributes[:kind] = kind if kind

          @attributes.freeze
        end

        #
        # The glob pattern to watch. See {@link GlobPattern glob pattern}
        # for more detail.
        #
        # @return [GlobPattern]
        def glob_pattern
          attributes.fetch(:globPattern)
        end

        #
        # The kind of events of interest. If omitted it defaults
        # to WatchKind.Create | WatchKind.Change | WatchKind.Delete
        # which is 7.
        #
        # @return [number]
        def kind
          attributes.fetch(:kind)
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
