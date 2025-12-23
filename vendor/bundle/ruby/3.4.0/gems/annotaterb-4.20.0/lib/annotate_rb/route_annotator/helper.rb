# frozen_string_literal: true

module AnnotateRb
  module RouteAnnotator
    module Helper
      MAGIC_COMMENT_MATCHER = /(^#\s*encoding:.*)|(^# coding:.*)|(^# -\*- coding:.*)|(^# -\*- encoding\s?:.*)|(^#\s*frozen_string_literal:.+)|(^# -\*- frozen_string_literal\s*:.+-\*-)/

      class << self
        def routes_file_exist?
          File.exist?(routes_file)
        end

        def routes_file
          @routes_rb ||= File.join("config", "routes.rb")
        end

        def strip_on_removal(content, header_position)
          if header_position == :before
            content.shift while content.first == ""
          elsif header_position == :after
            content.pop while content.last == ""
          end

          # Make sure we end on a trailing newline.
          content << "" unless content.last == ""

          # TODO: If the user buried it in the middle, we should probably see about
          # TODO: preserving a single line of space between the content above and
          # TODO: below...
          content
        end

        def rewrite_contents(existing_text, new_text)
          if existing_text == new_text
            false
          else
            File.open(routes_file, "wb") { |f| f.puts(new_text) }
            true
          end
        end

        # @param [Array<String>] content
        # @return [Array<String>] all found magic comments
        # @return [Array<String>] content without magic comments
        def extract_magic_comments_from_array(content_array)
          magic_comments = []
          new_content = []

          content_array.each do |row|
            if MAGIC_COMMENT_MATCHER.match?(row)
              magic_comments << row.strip
            else
              new_content << row
            end
          end

          [magic_comments, new_content]
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
end
