# frozen_string_literal: true

# This module provides methods for annotating config/routes.rb.
module AnnotateRb
  module RouteAnnotator
    # This class is abstract class of classes adding and removing annotation to config/routes.rb.
    class BaseProcessor
      class << self
        # @param options [Hash]
        # @param routes_file [String]
        # @return [String]
        def execute(options, routes_file)
          new(options, routes_file).execute
        end

        private :new
      end

      def initialize(options, routes_file)
        @options = options
        @routes_file = routes_file
      end

      # @return [Boolean]
      def update
        if existing_text == new_text
          false
        else
          if options[:frozen]
            abort "AnnotateRb error. #{routes_file} needs to be updated, but annotaterb was run with `--frozen`."
          end

          write(new_text)
          true
        end
      end

      def routes_file_exist?
        File.exist?(routes_file)
      end

      private

      attr_reader :options, :routes_file

      def generate_new_content_array(_content, _header_position)
        raise NoMethodError
      end

      def existing_text
        @existing_text ||= File.read(routes_file)
      end

      # @return [String]
      def new_text
        content, header_position = strip_annotations(existing_text)
        new_content = generate_new_content_array(content, header_position)
        new_content.join("\n")
      end

      def write(text)
        File.open(routes_file, "wb") { |f| f.puts(text) }
      end

      # TODO: write the method doc using ruby rdoc formats
      # This method returns an array of 'real_content' and 'header_position'.
      # 'header_position' will either be :before, :after, or
      # a number.  If the number is > 0, the
      # annotation was found somewhere in the
      # middle of the file.  If the number is
      # zero, no annotation was found.
      def strip_annotations(content)
        real_content = []
        mode = :content
        header_position = 0

        content.split(/\n/, -1).each_with_index do |line, line_number|
          if mode == :header && line !~ /\s*#/
            mode = :content
            real_content << line unless line.blank?
          elsif mode == :content
            if /^\s*#\s*== Route.*$/.match?(line)
              header_position = line_number + 1 # index start's at 0
              mode = :header
            else
              real_content << line
            end
          end
        end

        real_content_and_header_position(real_content, header_position)
      end

      def real_content_and_header_position(real_content, header_position)
        # By default assume the annotation was found in the middle of the file

        # ... unless we have evidence it was at the beginning ...
        return real_content, :before if header_position == 1

        # ... or that it was at the end.
        return real_content, :after if header_position >= real_content.count

        # and the default
        [real_content, header_position]
      end
    end
  end
end
