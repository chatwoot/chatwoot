# frozen_string_literal: true

require "unicode/emoji"

require_relative "display_width/constants"
require_relative "display_width/index"
require_relative "display_width/emoji_support"

module Unicode
  class DisplayWidth
    DEFAULT_AMBIGUOUS = 1
    INITIAL_DEPTH = 0x10000
    ASCII_NON_ZERO_REGEX = /[\0\x05\a\b\n-\x0F]/
    ASCII_NON_ZERO_STRING = "\0\x05\a\b\n-\x0F"
    ASCII_BACKSPACE = "\b"
    AMBIGUOUS_MAP = {
      1 => :WIDTH_ONE,
      2 => :WIDTH_TWO,
    }
    FIRST_AMBIGUOUS = {
      WIDTH_ONE: 768,
      WIDTH_TWO: 161,
    }
    NOT_COMMON_NARROW_REGEX = {
     WIDTH_ONE: /[^\u{10}-\u{2FF}]/m,
     WIDTH_TWO: /[^\u{10}-\u{A1}]/m,
    }
    FIRST_4096 = {
      WIDTH_ONE: decompress_index(INDEX[:WIDTH_ONE][0][0], 1),
      WIDTH_TWO: decompress_index(INDEX[:WIDTH_TWO][0][0], 1),
    }
    EMOJI_SEQUENCES_REGEX_MAPPING = {
      rgi: :REGEX_INCLUDE_MQE_UQE,
      rgi_at: :REGEX_INCLUDE_MQE_UQE,
      possible: :REGEX_WELL_FORMED,
    }
    REGEX_EMOJI_VS16 = Regexp.union(
      Regexp.compile(
        Unicode::Emoji::REGEX_TEXT_PRESENTATION.source +
        "(?<![#*0-9])" +
        "\u{FE0F}"
      ),
      Unicode::Emoji::REGEX_EMOJI_KEYCAP
    )

    # ebase = Unicode::Emoji::REGEX_PROP_MODIFIER_BASE.source
    REGEX_EMOJI_ALL_SEQUENCES = Regexp.union(/.[\u{1F3FB}-\u{1F3FF}\u{FE0F}]?(\u{200D}.[\u{1F3FB}-\u{1F3FF}\u{FE0F}]?)+|.[\u{1F3FB}-\u{1F3FF}]/, Unicode::Emoji::REGEX_EMOJI_KEYCAP)
    REGEX_EMOJI_ALL_SEQUENCES_AND_VS16 = Regexp.union(REGEX_EMOJI_ALL_SEQUENCES, REGEX_EMOJI_VS16)

    # Returns monospace display width of string
    def self.of(string, ambiguous = nil, overwrite = nil, old_options = {}, **options)
      # Binary strings don't make much sense when calculating display width.
      # Assume it's valid UTF-8
      if string.encoding == Encoding::BINARY && !string.force_encoding(Encoding::UTF_8).valid_encoding?
        # Didn't work out, go back to binary
        string.force_encoding(Encoding::BINARY)
      end

      string = string.encode(Encoding::UTF_8, invalid: :replace, undef: :replace) unless string.encoding == Encoding::UTF_8
      options = normalize_options(string, ambiguous, overwrite, old_options, **options)

      width = 0

      unless options[:overwrite].empty?
        width, string = width_custom(string, options[:overwrite])
      end

      if string.ascii_only?
        return width + width_ascii(string)
      end

      ambiguous_index_name = AMBIGUOUS_MAP[options[:ambiguous]]

      unless string.match?(NOT_COMMON_NARROW_REGEX[ambiguous_index_name])
        return width + string.size
      end

      # Retrieve Emoji width
      if options[:emoji] != :none
        e_width, string = emoji_width(
          string,
          options[:emoji],
          options[:ambiguous],
        )
        width += e_width

        unless string.match?(NOT_COMMON_NARROW_REGEX[ambiguous_index_name])
          return width + string.size
        end
      end

      index_full = INDEX[ambiguous_index_name]
      index_low = FIRST_4096[ambiguous_index_name]
      first_ambiguous = FIRST_AMBIGUOUS[ambiguous_index_name]

      string.each_codepoint{ |codepoint|
        if codepoint > 15 && codepoint < first_ambiguous
          width += 1
        elsif codepoint < 0x1001
          width += index_low[codepoint] || 1
        else
          d = INITIAL_DEPTH
          w = index_full[codepoint / d]
          while w.instance_of? Array
            w = w[(codepoint %= d) / (d /= 16)]
          end

          width += w || 1
        end
      }

      # Return result + prevent negative lengths
      width < 0 ? 0 : width
    end

    # Returns width of custom overwrites and remaining string
    def self.width_custom(string, overwrite)
      width = 0

      string = string.each_codepoint.select{ |codepoint|
        if overwrite[codepoint]
          width += overwrite[codepoint]
          nil
        else
          codepoint
        end
      }.pack("U*")

      [width, string]
    end

    # Returns width for ASCII-only strings. Will consider zero-width control symbols.
    def self.width_ascii(string)
      if string.match?(ASCII_NON_ZERO_REGEX)
        res = string.delete(ASCII_NON_ZERO_STRING).bytesize - string.count(ASCII_BACKSPACE)
        return res < 0 ? 0 : res
      end

      string.bytesize
    end

    # Returns width of all considered Emoji and remaining string
    def self.emoji_width(string, mode = :all, ambiguous = DEFAULT_AMBIGUOUS)
      res = 0

      if emoji_set_regex = EMOJI_SEQUENCES_REGEX_MAPPING[mode]
        emoji_width_via_possible(
          string,
          Unicode::Emoji.const_get(emoji_set_regex),
          mode == :rgi_at,
          ambiguous,
        )

      elsif mode == :all_no_vs16
        no_emoji_string = string.gsub(REGEX_EMOJI_ALL_SEQUENCES){ res += 2; "" }
        [res, no_emoji_string]

      elsif mode == :vs16
        no_emoji_string = string.gsub(REGEX_EMOJI_VS16){ res += 2; "" }
        [res, no_emoji_string]

      elsif mode == :all
        no_emoji_string = string.gsub(REGEX_EMOJI_ALL_SEQUENCES_AND_VS16){ res += 2; "" }
        [res, no_emoji_string]

      else
        [0, string]

      end
    end

    # Match possible Emoji first, then refine
    def self.emoji_width_via_possible(string, emoji_set_regex, strict_eaw = false, ambiguous = DEFAULT_AMBIGUOUS)
      res = 0

      # For each string possibly an emoji
      no_emoji_string = string.gsub(REGEX_EMOJI_ALL_SEQUENCES_AND_VS16){ |emoji_candidate|
        # Check if we have a combined Emoji with width 2 (or EAW an Apple Terminal)
        if emoji_candidate == emoji_candidate[emoji_set_regex]
          if strict_eaw
            res += self.of(emoji_candidate[0], ambiguous, emoji: false)
          else
            res += 2
          end
          ""

        # We are dealing with a default text presentation emoji or a well-formed sequence not matching the above Emoji set
        else
          if !strict_eaw
            # Ensure all explicit VS16 sequences have width 2
            emoji_candidate.gsub!(REGEX_EMOJI_VS16){ res += 2; "" }
          end

          emoji_candidate
        end
      }

      [res, no_emoji_string]
    end

    def self.normalize_options(string, ambiguous = nil, overwrite = nil, old_options = {}, **options)
      unless old_options.empty?
        warn "Unicode::DisplayWidth: Please migrate to keyword arguments - #{old_options.inspect}"
        options.merge! old_options
      end

      options[:ambiguous] = ambiguous if ambiguous
      options[:ambiguous] ||= DEFAULT_AMBIGUOUS

      if options[:ambiguous] != 1 && options[:ambiguous] != 2
        raise ArgumentError, "Unicode::DisplayWidth: Ambiguous width must be 1 or 2"
      end

      if overwrite && !overwrite.empty?
        warn "Unicode::DisplayWidth: Please migrate to keyword arguments - overwrite: #{overwrite.inspect}"
        options[:overwrite] = overwrite
      end
      options[:overwrite] ||= {}

      if [nil, true, :auto].include?(options[:emoji])
        options[:emoji] = EmojiSupport.recommended
      elsif options[:emoji] == false
        options[:emoji] = :none
      end

      options
    end

    def initialize(ambiguous: DEFAULT_AMBIGUOUS, overwrite: {}, emoji: true)
      @ambiguous = ambiguous
      @overwrite = overwrite
      @emoji     = emoji
    end

    def get_config(**kwargs)
      {
        ambiguous: kwargs[:ambiguous] || @ambiguous,
        overwrite: kwargs[:overwrite] || @overwrite,
        emoji:     kwargs[:emoji]     || @emoji,
      }
    end

    def of(string, **kwargs)
      self.class.of(string, **get_config(**kwargs))
    end
  end
end
