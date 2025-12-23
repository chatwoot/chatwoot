module AnnotateRb
  module RouteAnnotator
    class HeaderGenerator
      PREFIX = "== Route Map".freeze
      PREFIX_MD = "## Route Map".freeze
      HEADER_ROW = ["Prefix", "Verb", "URI Pattern", "Controller#Action"].freeze

      class << self
        def generate(options = {})
          new(options, routes_map(options)).generate
        end

        private :new

        private

        def routes_map(options)
          result = `rails routes`.chomp("\n").split(/\n/, -1)

          # In old versions of Rake, the first line of output was the cwd.  Not so
          # much in newer ones.  We ditch that line if it exists, and if not, we
          # keep the line around.
          result.shift if %r{^\(in /}.match?(result.first)

          ignore_routes = options[:ignore_routes]
          regexp_for_ignoring_routes = ignore_routes ? /#{ignore_routes}/ : nil

          # Skip routes which match given regex
          # Note: it matches the complete line (route_name, path, controller/action)
          if regexp_for_ignoring_routes
            result.reject { |line| line =~ regexp_for_ignoring_routes }
          else
            result
          end
        end
      end

      def initialize(options, routes_map)
        @options = options
        @routes_map = routes_map
      end

      def generate
        magic_comments_map, contents_without_magic_comments = Helper.extract_magic_comments_from_array(routes_map)

        out = []

        magic_comments_map.each do |magic_comment|
          out << magic_comment
        end
        out << "" if magic_comments_map.any?

        out << comment(options[:wrapper_open]) if options[:wrapper_open]

        out << comment(markdown? ? PREFIX_MD : PREFIX) + timestamp_if_required
        out << comment
        return out if contents_without_magic_comments.size.zero?

        maxs = [HEADER_ROW.map(&:size)] + contents_without_magic_comments[1..-1].map { |line| line.split.map(&:size) }

        if markdown?
          max = maxs.map(&:max).compact.max

          out << comment(content(HEADER_ROW, maxs))
          out << comment(content(["-" * max, "-" * max, "-" * max, "-" * max], maxs))
        else
          out << comment(content(contents_without_magic_comments[0], maxs))
        end

        out += contents_without_magic_comments[1..-1].map { |line| comment(content(markdown? ? line.split(" ") : line, maxs)) }
        out << comment(options[:wrapper_close]) if options[:wrapper_close]

        out
      end

      private

      attr_reader :options, :routes_map

      def comment(row = "")
        if row == ""
          "#"
        else
          "# #{row}"
        end
      end

      def content(line, maxs)
        return line.rstrip unless markdown?

        line.each_with_index.map { |elem, index| format_line_element(elem, maxs, index) }.join(" | ")
      end

      def format_line_element(elem, maxs, index)
        min_length = maxs.map { |arr| arr[index] }.max || 0
        format("%-#{min_length}.#{min_length}s", elem.tr("|", "-"))
      end

      def markdown?
        options[:format_markdown]
      end

      def timestamp_if_required(time = Time.now)
        if options[:timestamp]
          time_formatted = time.strftime("%Y-%m-%d %H:%M")
          " (Updated #{time_formatted})"
        else
          ""
        end
      end
    end
  end
end
