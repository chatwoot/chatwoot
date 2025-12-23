require 'tilt/template'
require 'pandoc-ruby'

module Tilt
  # Pandoc markdown implementation. See:
  # http://pandoc.org/
  class PandocTemplate < Template
    self.default_mime_type = 'text/html'

    # turn options hash into an array
    # Map tilt options to pandoc options
    # Replace hash keys with value true with symbol for key
    # Remove hash keys with value false
    # Leave other hash keys untouched
    def pandoc_options
      result = []
      from = "markdown"
      smart_extension = "-smart"
      options.each do |k,v|
        case k
        when :smartypants
          smart_extension = "+smart" if v
        when :escape_html
          from = "markdown-raw_html" if v
        when :commonmark
          from = "commonmark" if v
        when :markdown_strict
          from = "markdown_strict" if v
        else
          case v
          when true
            result << k
          when false
            # do nothing
          else
            result << { k => v }
          end
        end
      end
      result << { :f => from + smart_extension }
      result
    end

    def prepare
      @engine = PandocRuby.new(data, *pandoc_options)
      @output = nil
    end

    def evaluate(scope, locals, &block)
      @output ||= @engine.to_html.strip
    end

    def allows_script?
      false
    end
  end
end
