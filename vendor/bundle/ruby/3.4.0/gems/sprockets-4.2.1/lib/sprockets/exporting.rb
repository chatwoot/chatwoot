module Sprockets
  # `Exporting` is an internal mixin whose public methods are exposed on
  # the `Environment` and `CachedEnvironment` classes.
  module Exporting
    # Exporters are ran on the assets:precompile task
    def exporters
      config[:exporters]
    end

    # Public: Registers a new Exporter `klass` for `mime_type`.
    #
    # If your exporter depends on one or more other exporters you can
    # specify this via the `depend_on` keyword.
    #
    #     register_exporter '*/*', Sprockets::Exporters::ZlibExporter
    #
    # This ensures that `Sprockets::Exporters::File` will always execute before
    # `Sprockets::Exporters::Zlib`
    def register_exporter(mime_types, klass = nil)
      mime_types = Array(mime_types)

      mime_types.each do |mime_type|
        self.config = hash_reassoc(config, :exporters, mime_type) do |_exporters|
          _exporters << klass
        end
      end
    end

    # Public: Remove Exporting processor `klass` for `mime_type`.
    #
    #     environment.unregister_exporter '*/*', Sprockets::Exporters::ZlibExporter
    #
    # Can be called without a mime type
    #
    #     environment.unregister_exporter Sprockets::Exporters::ZlibExporter
    #
    # Does not remove any exporters that depend on `klass`.
    def unregister_exporter(mime_types, exporter = nil)
      unless mime_types.is_a? Array
        if mime_types.is_a? String
          mime_types = [mime_types]
        else # called with no mime type
          exporter = mime_types
          mime_types = nil
        end
      end

      self.config = hash_reassoc(config, :exporters) do |_exporters|
        _exporters.each do |mime_type, exporters_array|
          next if mime_types && !mime_types.include?(mime_type)
          if exporters_array.include? exporter
            _exporters[mime_type] = exporters_array.dup.delete exporter
          end
        end
      end
    end

    # Public: Checks if concurrent exporting is allowed
    def export_concurrent
      config[:export_concurrent]
    end

    # Public: Enable or disable the concurrently exporting files
    #
    # Defaults to true.
    #
    #     environment.export_concurrent = false
    #
    def export_concurrent=(export_concurrent)
      self.config = config.merge(export_concurrent: export_concurrent).freeze
    end
  end
end
