require 'tilt/template'
require 'commonmarker'

module Tilt
  class CommonMarkerTemplate < Template
    self.default_mime_type = 'text/html'

    OPTION_ALIAS = {
      :smartypants => :SMART
    }
    PARSE_OPTIONS = [
      :FOOTNOTES,
      :LIBERAL_HTML_TAG,
      :SMART,
      :smartypants,
      :STRIKETHROUGH_DOUBLE_TILDE,
      :UNSAFE,
      :VALIDATE_UTF8,
    ].freeze
    RENDER_OPTIONS = [
      :FOOTNOTES,
      :FULL_INFO_STRING,
      :GITHUB_PRE_LANG,
      :HARDBREAKS,
      :NOBREAKS,
      :SAFE, # Removed in v0.18.0 (2018-10-17)
      :SOURCEPOS,
      :TABLE_PREFER_STYLE_ATTRIBUTES,
      :UNSAFE,
    ].freeze
    EXTENSIONS = [
      :autolink,
      :strikethrough,
      :table,
      :tagfilter,
      :tasklist,
    ].freeze

    def extensions
      EXTENSIONS.select do |extension|
        options[extension]
      end
    end

    def parse_options
      raw_options = PARSE_OPTIONS.select do |option|
        options[option]
      end
      actual_options = raw_options.map do |option|
        OPTION_ALIAS[option] || option
      end

      if actual_options.any?
        actual_options
      else
        :DEFAULT
      end
    end

    def render_options
      raw_options = RENDER_OPTIONS.select do |option|
        options[option]
      end
      actual_options = raw_options.map do |option|
        OPTION_ALIAS[option] || option
      end
      if actual_options.any?
        actual_options
      else
        :DEFAULT
      end
    end

    def prepare
      @engine = nil
      @output = nil
    end

    def evaluate(scope, locals, &block)
      doc = CommonMarker.render_doc(data, parse_options, extensions)
      doc.to_html(render_options, extensions)
    end

    def allows_script?
      false
    end
  end
end
