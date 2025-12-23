# frozen_string_literal: true

# Generator for stringprep regexps.
#
# Combines Unicode character classes with generated tables.  Generated regexps
# are still used to test that the written regexps conform to the specification.
# Some tables don't match up well with any character properties available to
# ruby's regexp engine.  Those use the table-generated regexps.
class StringPrepTablesGenerator
  STRINGPREP_RFC_FILE  = "rfcs/rfc3454.txt"
  STRINGPREP_JSON_FILE = "rfcs/rfc3454-stringprep_tables.json"

  # valid UTF-8 can't contain these codepoints
  # checking for them anyway, using /\p{Cs}/  ;)
  SURROGATES_RANGE = 0xD800..0xDFFF

  attr_reader :json_filename, :rfc_filename

  def initialize(rfc_filename:  STRINGPREP_RFC_FILE,
                 json_filename: STRINGPREP_JSON_FILE)
    @rfc_filename  = rfc_filename
    @json_filename = json_filename
  end

  # for rake deps
  def json_deps;  Rake::FileList.new __FILE__, STRINGPREP_RFC_FILE  end
  def rb_deps;    Rake::FileList.new __FILE__, STRINGPREP_JSON_FILE end
  def clean_deps; Rake::FileList.new           STRINGPREP_JSON_FILE end

  def generate_json_data_file
    require "json"
    rfc_filename
      .then(&File.method(:read))
      .then(&method(:parse_rfc_text))
      .then(&JSON.method(:pretty_generate))
      .then {|data| File.write json_filename, data }
  end

  def tables;  @tables  ||= load_tables_and_titles_from_json!.first end
  def titles;  @titles  ||= load_tables_and_titles_from_json!.last end
  def ranges;  @ranges  ||= tables.transform_values(&method(:to_ranges)) end
  def arrays;  @arrays  ||= ranges.transform_values{|t| t.flat_map(&:to_a) } end
  def sets;    @sets    ||= arrays.transform_values(&:to_set) end
  def regexps; @regexps ||= arrays.transform_values(&method(:to_regexp)) end
  def asgn_regexps; @asgn_regexps || asgn_regexps! end

  def merged_tables_regex(*table_names, negate: false)
    table_names
      .flat_map(&arrays.method(:fetch))
      .then {|array| to_regexp(array, negate: negate) }
  end

  def regexp_for(*names, negate: false)
    asgn_regexps[[*names, negate]] ||= merged_tables_regex(*names, negate: negate)
  end

  def stringprep_rb
    <<~RUBY
      # frozen_string_literal: true

      #--
      # This file is generated from RFC3454, by rake.  Don't edit directly.
      #++

      module Net::IMAP::StringPrep

        module Tables

          #{asgn_table "A.1"}

          #{asgn_table "B.1"}

          #{asgn_table "B.2"}

          #{asgn_table "B.3"}

          #{asgn_mapping "B.1", ""}

          #{asgn_mapping "B.2"}

          #{asgn_mapping "B.3"}

          #{asgn_table "C.1.1"}

          #{asgn_table "C.1.2"}

          #{asgn_table "C.2.1"}

          #{asgn_table "C.2.2"}

          #{asgn_table "C.3"}

          #{asgn_table "C.4"}

          #{asgn_table "C.5"}

          #{asgn_table "C.6"}

          #{asgn_table "C.7"}

          #{asgn_table "C.8"}

          #{asgn_table "C.9"}

          #{asgn_table "D.1"}

          # Used to check req3 of bidirectional checks
          #{asgn_table "D.1", negate: true}

          #{asgn_table "D.2"}

          BIDI_DESC_REQ2 = "A string with RandALCat characters must not contain LCat characters."

          # Bidirectional Characters [StringPrep, §6], Requirement 2
          # >>>
          #   If a string contains any RandALCat character, the string MUST NOT
          #   contain any LCat character.
          BIDI_FAILS_REQ2 = #{bidi_fails_req2.inspect}.freeze

          BIDI_DESC_REQ3 = "A string with RandALCat characters must start and end with RandALCat characters."

          # Bidirectional Characters [StringPrep, §6], Requirement 3
          # >>>
          #   If a string contains any RandALCat character, a RandALCat
          #   character MUST be the first character of the string, and a
          #   RandALCat character MUST be the last character of the string.
          BIDI_FAILS_REQ3 = #{bidi_fails_req3.inspect}.freeze

          # Bidirectional Characters [StringPrep, §6]
          BIDI_FAILURE = #{bidi_failure_regexp.inspect}.freeze

          # Names of each codepoint table in the RFC-3454 appendices
          TITLES = {
            #{table_titles_rb}
          }.freeze

          # Regexps matching each codepoint table in the RFC-3454 appendices
          REGEXPS = {
            #{table_regexps_rb}
          }.freeze

          MAPPINGS = {
            "B.1" => [IN_B_1, MAP_B_1].freeze,
            "B.2" => [IN_B_2, MAP_B_2].freeze,
            "B.3" => [IN_B_3, MAP_B_3].freeze,
          }.freeze

        end
      end
    RUBY
  end

  def table_titles_rb(indent = 3)
    titles
      .map{|t| "%p => %p," % t }
      .join("\n#{"  "*indent}")
  end

  def table_regexps_rb(indent = 3)
    asgn_regexps # => { ["A.1", false] => regexp, ... }
      .reject {|(_, n), _| n }
      .map {|(t, _), _| "%p => %s," % [t, regexp_const_name(t)] }
      .join("\n#{"  "*indent}")
  end

  def saslprep_rb
    <<~RUBY
      # frozen_string_literal: true

      #--
      # This file is generated from RFC3454, by rake.  Don't edit directly.
      #++

      module Net::IMAP::StringPrep

        module SASLprep

          # RFC4013 §2.1 Mapping - mapped to space
          # >>>
          #   non-ASCII space characters (\\StringPrep\\[\\"C.1.2\\"]) that can
          #   be mapped to SPACE (U+0020)
          #
          # Equal to \\StringPrep\\[\\"C.1.2\\"].
          # Redefined here to avoid loading StringPrep::Tables unless necessary.
          MAP_TO_SPACE = #{regex_str "C.1.2"}

          # RFC4013 §2.1 Mapping - mapped to nothing
          # >>>
          #   the "commonly mapped to nothing" characters
          #   (\\StringPrep\\[\\"B.1\\"]) that can be mapped to nothing.
          #
          # Equal to \\StringPrep\\[\\"B.1\\"].
          # Redefined here to avoid loading StringPrep::Tables unless necessary.
          MAP_TO_NOTHING = #{regex_str "B.1"}

          # RFC4013 §2.3 Prohibited Output
          # >>>
          # * Non-ASCII space characters — \\StringPrep\\[\\"C.1.2\\"]
          # * ASCII control characters — \\StringPrep\\[\\"C.2.1\\"]
          # * Non-ASCII control characters — \\StringPrep\\[\\"C.2.2\\"]
          # * Private Use characters — \\StringPrep\\[\\"C.3\\"]
          # * Non-character code points — \\StringPrep\\[\\"C.4\\"]
          # * Surrogate code points — \\StringPrep\\[\\"C.5\\"]
          # * Inappropriate for plain text characters — \\StringPrep\\[\\"C.6\\"]
          # * Inappropriate for canonical representation characters — \\StringPrep\\[\\"C.7\\"]
          # * Change display properties or deprecated characters — \\StringPrep\\[\\"C.8\\"]
          # * Tagging characters — \\StringPrep\\[\\"C.9\\"]
          TABLES_PROHIBITED = #{SASL_TABLES_PROHIBITED.inspect}.freeze

          # Adds unassigned (by Unicode 3.2) codepoints to TABLES_PROHIBITED.
          #
          # RFC4013 §2.5 Unassigned Code Points
          # >>>
          #   This profile specifies the \\StringPrep\\[\\"A.1\\"] table as its
          #   list of unassigned code points.
          TABLES_PROHIBITED_STORED = ["A.1", *TABLES_PROHIBITED].freeze

          # A Regexp matching codepoints prohibited by RFC4013 §2.3.
          #
          # This combines all of the TABLES_PROHIBITED tables.
          PROHIBITED_OUTPUT = #{regex_str(*SASL_TABLES_PROHIBITED)}

          # RFC4013 §2.5 Unassigned Code Points
          # >>>
          #   This profile specifies the \\StringPrep\\[\\"A.1\\"] table as its
          #   list of unassigned code points.
          #
          # Equal to \\StringPrep\\[\\"A.1\\"].
          # Redefined here to avoid loading StringPrep::Tables unless necessary.
          UNASSIGNED = #{regex_str "A.1"}

          # A Regexp matching codepoints prohibited by RFC4013 §2.3 and §2.5.
          #
          # This combines PROHIBITED_OUTPUT and UNASSIGNED.
          PROHIBITED_OUTPUT_STORED = Regexp.union(
            UNASSIGNED, PROHIBITED_OUTPUT
          ).freeze

          # Bidirectional Characters [StringPrep, §6]
          #
          # A Regexp for strings that don't satisfy StringPrep's Bidirectional
          # Characters rules.
          #
          # Equal to StringPrep::Tables::BIDI_FAILURE.
          # Redefined here to avoid loading StringPrep::Tables unless necessary.
          BIDI_FAILURE = #{bidi_failure_regexp.inspect}.freeze

          # A Regexp matching strings prohibited by RFC4013 §2.3 and §2.4.
          #
          # This combines PROHIBITED_OUTPUT and BIDI_FAILURE.
          PROHIBITED = Regexp.union(
            PROHIBITED_OUTPUT, BIDI_FAILURE,
          )

          # A Regexp matching strings prohibited by RFC4013 §2.3, §2.4, and §2.5.
          #
          # This combines PROHIBITED_OUTPUT_STORED and BIDI_FAILURE.
          PROHIBITED_STORED = Regexp.union(
            PROHIBITED_OUTPUT_STORED, BIDI_FAILURE,
          )

        end
      end
    RUBY
  end

  private

  def parse_rfc_text(rfc3454_text)
    titles = {}
    tables, = rfc3454_text
      .lines
      .each_with_object([]) {|line, acc|
        current, table = acc.last
        case line
        when /^([A-D]\.[1-9](?:\.[1-9])?) (.*)/
          titles[$1] = $2
        when /^ {3}-{5} Start Table (\S*)/
          acc << [$1, []]
        when /^ {3}-{5} End Table /
          acc << [nil, nil]
        when /^ {3}([0-9A-F]+); ([ 0-9A-F]*)(?:;[^;]*)$/  # mapping tables
          table << [$1, $2.split(/ +/)] if current
        when /^ {3}([-0-9A-F]+)(?:;[^;]*)?$/              # regular tables
          table << $1 if current
        when /^ {3}(.*)/
          raise "expected to match %p" % $1 if current
        end
      }
      .to_h.compact
      .transform_values {|t| t.first.size == 2 ? t.to_h : t }
    tables["titles"] = titles
    tables
  end

  def load_tables_and_titles_from_json!
    require "json"
    @tables = json_filename
      .then(&File.method(:read))
      .then(&JSON.method(:parse))
    @titles = @tables.delete "titles"
    [@tables, @titles]
  end

  def to_ranges(table)
    (table.is_a?(Hash) ? table.keys : table)
      .map{|range| range.split(?-).map{|cp| Integer cp, 16} }
      .map{|s,e| s..(e || s)}
  end

  # TODO: DRY with unicode_normalize
  def to_map(table)
    table = table.to_hash
      .transform_keys { Integer _1, 16 }
      .transform_keys { [_1].pack("U*") }
      .transform_values {|cps| cps.map { Integer _1, 16 } }
      .transform_values { _1.pack("U*") }
  end

  # Starting from a codepoints array (rather than ranges) to deduplicate merged
  # tables.
  def to_regexp(codepoints, negate: false)
    codepoints
      .grep_v(SURROGATES_RANGE) # remove surrogate codepoints from C.5 and D.2
      .uniq
      .sort
      .chunk_while {|cp1,cp2| cp1 + 1 == cp2 }     # find contiguous chunks
      .map {|chunk| chunk.map{|cp| "%04x" % cp } } # convert to hex strings
      .partition {|chunk| chunk[1] }               # ranges vs singles
      .then {|ranges, singles|
        singles.flatten!
        [
          negate ? "^" : "",
          singles.flatten.any? ? "\\u{%s}" % singles.join(" ") : "",
          ranges.map {|r| "\\u{%s}-\\u{%s}" % [r.first, r.last] }.join,
          codepoints.any?(SURROGATES_RANGE) ? "\\p{Cs}" : "", # not necessary :)
        ].join
      }
      .then {|char_class| Regexp.new "[#{char_class}]" }
  end

  def asgn_regexps!
    @asgn_regexps = {}
    # preset the regexp for each table
    asgn_regex "A.1", /\p{^AGE=3.2}/
    # If ruby supported all unicode properties (i.e. line break = word joiner):
    #   /[\u{00ad 034f 1806}\p{join_c}\p{VS}\p{lb=WJ}&&\p{age=3.2}]/
    asgn_table "B.1"
    asgn_table "B.2"
    asgn_table "B.3"
    asgn_regex "C.1.1", / /
    asgn_regex "C.1.2", /[\u200b\p{Zs}&&[^ ]]/
    asgn_regex "C.2.1", /[\x00-\x1f\x7f]/
    # C.2.2 is a union:
    #   Cc + Cf (as defined by Unicode 3.2) + Zl + Zp + 0xfffc
    #   - any codepoints covered by C.2.1 or C.8 or C.9
    #
    # But modern Unicode properties are significantly different, so it's better
    # to just load the table definition.
    asgn_table "C.2.2"
    asgn_regex "C.3", /\p{private use}/
    asgn_regex "C.4", /\p{noncharacter code point}/
    asgn_regex "C.5", /\p{surrogate}/
    asgn_regex "C.6", /[\p{in specials}&&\p{AGE=3.2}&&\p{^NChar}]/
    asgn_regex "C.7", /[\p{in ideographic description characters}&&\p{AGE=3.2}]/
    # C.8 is a union of \p{Bidi Control} and Unicode 3.2 properties.  But those properties
    # have changed for modern Unicode, and thus for modern ruby's regexp
    # character properties.  It's better to just load the table definition.
    asgn_table "C.8"
    asgn_regex "C.9", /[\p{in Tags}&&\p{AGE=3.2}]/
    # Unfortunately, ruby doesn't (currently) support /[\p{Bidi
    # Class=R}\p{bc=AL}]/.  On the other hand, StringPrep (based on Unicode 3.2)
    # might not be a good match for the modern (14.0) property value anyway.
    asgn_table "D.1"
    asgn_table "D.1", negate: true # used by BIDI_FAILS_REQ3
    asgn_table "D.2"
    @asgn_regexps
  end

  def regex_str(*names, negate: false)
    "%p.freeze" % regexp_for(*names, negate: negate)
  end

  def asgn_table(name, negate: false)
    asgn_regex(name, regexp_for(name, negate: negate), negate: negate)
  end

  def asgn_mapping(name, replacement = to_map(tables[name]))
    cname = name.tr(?., ?_).upcase
    "# Replacements for %s\n%s%s = %p.freeze" % [
      "IN_#{name}", "  " * 2, "MAP_#{cname}", replacement,
    ]
  end

  def regexp_const_desc(name, negate: false)
    if negate then "Matches the negation of the %s table" % [name]
    else %q{%s \\StringPrep\\[\\"%s\\"]} % [titles.fetch(name), name]
    end
  end

  def regexp_const_name(table_name, negate: false)
    "IN_%s%s" % [table_name.tr(".", "_"), negate ? "_NEGATED" : ""]
  end

  def asgn_regex(name, regexp, negate: false)
    asgn_regexps[[name, negate]] = regexp
    "# %s\n%s%s = %p.freeze" % [
      regexp_const_desc(name, negate: negate), " " * 4,
      regexp_const_name(name, negate: negate),
      regexp,
    ]
  end

  def bidi_R_AL     ; regexp_for "D.1" end
  def bidi_not_R_AL ; regexp_for "D.1", negate: true end
  def bidi_L        ; regexp_for "D.2" end

  def bidi_fails_req2
    Regexp.union(
      /#{bidi_R_AL}.*?#{bidi_L}/mu, # RandALCat followed by LCat
      /#{bidi_L}.*?#{bidi_R_AL}/mu, # RandALCat preceded by LCat
    )
  end

  def bidi_fails_req3
    # contains RandALCat:
    Regexp.union(
      /\A#{bidi_not_R_AL}.*?#{bidi_R_AL}/mu, # but doesn't start with RandALCat
      /#{bidi_R_AL}.*?#{bidi_not_R_AL}\z/mu, # but doesn't end   with RandALCat
    )
  end

  def bidi_failure_regexp
    Regexp.union(bidi_fails_req2, bidi_fails_req3)
  end

  SASL_TABLES_PROHIBITED = %w[
    C.1.2 C.2.1 C.2.2 C.3 C.4 C.5 C.6 C.7 C.8 C.9
  ].freeze

  SASL_TABLES_PROHIBITED_STORED = %w[
    A.1 C.1.2 C.2.1 C.2.2 C.3 C.4 C.5 C.6 C.7 C.8 C.9
  ].freeze

end
