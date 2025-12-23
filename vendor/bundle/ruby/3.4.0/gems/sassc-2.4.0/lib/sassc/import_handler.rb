# frozen_string_literal: true

module SassC
  class ImportHandler
    def initialize(options)
      @importer = if options[:importer]
        options[:importer].new(options)
      else
        nil
      end
    end

    def setup(native_options)
      return unless @importer

      importer_callback = Native.make_importer(import_function, nil)

      list = Native.make_function_list(1)
      Native::function_set_list_entry(list, 0, importer_callback)

      Native.option_set_c_importers(native_options, list)
    end

    private

    def import_function
      @import_function ||= FFI::Function.new(:pointer, [:string, :pointer, :pointer]) do |path, importer_entry, compiler|
        last_import = Native::compiler_get_last_import(compiler)
        parent_path = Native::import_get_abs_path(last_import)

        imports = [*@importer.imports(path, parent_path)]
        imports_to_native(imports)
      end
    end

    def imports_to_native(imports)
      import_list = Native.make_import_list(imports.size)

      imports.each_with_index do |import, i|
        source = import.source ? Native.native_string(import.source) : nil
        source_map_path = nil

        entry = Native.make_import_entry(import.path, source, source_map_path)
        Native.import_set_list_entry(import_list, i, entry)
      end

      import_list
    end
  end
end
