module Sass
  module Tree
    # A static node that wraps the {Sass::Tree} for an `@import`ed file.
    # It doesn't have a functional purpose other than to add the `@import`ed file
    # to the backtrace if an error occurs.
    class ImportNode < RootNode
      # The name of the imported file as it appears in the Sass document.
      #
      # @return [String]
      attr_reader :imported_filename

      # Sets the imported file.
      attr_writer :imported_file

      # @param imported_filename [String] The name of the imported file
      def initialize(imported_filename)
        @imported_filename = imported_filename
        super(nil)
      end

      def invisible?; to_s.empty?; end

      # Returns the imported file.
      #
      # @return [Sass::Engine]
      # @raise [Sass::SyntaxError] If no file could be found to import.
      def imported_file
        @imported_file ||= import
      end

      # Returns whether or not this import should emit a CSS @import declaration
      #
      # @return [Boolean] Whether or not this is a simple CSS @import declaration.
      def css_import?
        if @imported_filename =~ /\.css$/
          @imported_filename
        elsif imported_file.is_a?(String) && imported_file =~ /\.css$/
          imported_file
        end
      end

      private

      def import
        paths = @options[:load_paths]

        if @options[:importer]
          f = @options[:importer].find_relative(
            @imported_filename, @options[:filename], options_for_importer)
          return f if f
        end

        paths.each do |p|
          f = p.find(@imported_filename, options_for_importer)
          return f if f
        end

        lines = ["File to import not found or unreadable: #{@imported_filename}."]

        if paths.size == 1
          lines << "Load path: #{paths.first}"
        elsif !paths.empty?
          lines << "Load paths:\n  #{paths.join("\n  ")}"
        end
        raise SyntaxError.new(lines.join("\n"))
      rescue SyntaxError => e
        raise SyntaxError.new(e.message, :line => line, :filename => @filename)
      end

      def options_for_importer
        @options.merge(:_from_import_node => true)
      end
    end
  end
end
