# frozen_string_literal: true

module CommonMarker
  # For Ruby::Enum, these must be classes, not modules
  module Config
    # See https://github.com/github/cmark-gfm/blob/master/src/cmark-gfm.h#L673
    OPTS = {
      parse: {
        DEFAULT: 0,
        SOURCEPOS: (1 << 1),
        UNSAFE: (1 << 17),
        VALIDATE_UTF8: (1 << 9),
        SMART: (1 << 10),
        LIBERAL_HTML_TAG: (1 << 12),
        FOOTNOTES: (1 << 13),
        STRIKETHROUGH_DOUBLE_TILDE: (1 << 14),
      }.freeze,
      render: {
        DEFAULT: 0,
        SOURCEPOS: (1 << 1),
        HARDBREAKS: (1 << 2),
        UNSAFE: (1 << 17),
        NOBREAKS: (1 << 4),
        VALIDATE_UTF8: (1 << 9),
        SMART: (1 << 10),
        GITHUB_PRE_LANG: (1 << 11),
        LIBERAL_HTML_TAG: (1 << 12),
        FOOTNOTES: (1 << 13),
        STRIKETHROUGH_DOUBLE_TILDE: (1 << 14),
        TABLE_PREFER_STYLE_ATTRIBUTES: (1 << 15),
        FULL_INFO_STRING: (1 << 16),
      }.freeze,
      format: [:html, :xml, :commonmark, :plaintext].freeze,
    }.freeze

    class << self
      def process_options(option, type)
        case option
        when Symbol
          OPTS.fetch(type).fetch(option)
        when Array
          raise TypeError if option.none?

          # neckbearding around. the map will both check the opts and then bitwise-OR it
          OPTS.fetch(type).fetch_values(*option).inject(0, :|)
        else
          raise TypeError, "option type must be a valid symbol or array of symbols within the #{name}::OPTS[:#{type}] context"
        end
      rescue KeyError => e
        raise TypeError, "option ':#{e.key}' does not exist for #{name}::OPTS[:#{type}]"
      end
  end
  end
end
