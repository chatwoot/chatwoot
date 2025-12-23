# frozen_string_literal: true

module Net
  class IMAP < Protocol

    # Regexps and utility methods for implementing stringprep profiles.  The
    # \StringPrep algorithm is defined by
    # {RFC-3454}[https://www.rfc-editor.org/rfc/rfc3454.html].  Each
    # codepoint table defined in the RFC-3454 appendices is matched by a Regexp
    # defined in this module.
    module StringPrep
      autoload :NamePrep, File.expand_path("stringprep/nameprep", __dir__)
      autoload :SASLprep, File.expand_path("stringprep/saslprep", __dir__)
      autoload :Tables,   File.expand_path("stringprep/tables",   __dir__)
      autoload :Trace,    File.expand_path("stringprep/trace",    __dir__)

      # ArgumentError raised when +string+ is invalid for the stringprep
      # +profile+.
      class StringPrepError < ArgumentError
        attr_reader :string, :profile

        def initialize(*args, string: nil, profile: nil)
          @string  = -string.to_str  unless string.nil?
          @profile = -profile.to_str unless profile.nil?
          super(*args)
        end
      end

      # StringPrepError raised when +string+ contains a codepoint prohibited by
      # +table+.
      class ProhibitedCodepoint < StringPrepError
        attr_reader :table

        def initialize(table, *args, **kwargs)
          @table  = table
          details = (title = Tables::TITLES[table]) ?
            "%s [%s]" % [title, table] : table
          message = "String contains a prohibited codepoint: %s" % [details]
          super(message, *args, **kwargs)
        end
      end

      # StringPrepError raised when +string+ contains bidirectional characters
      # which violate the StringPrep requirements.
      class BidiStringError < StringPrepError
      end

      # Returns a Regexp matching the given +table+ name.
      def self.[](table)
        Tables::REGEXPS.fetch(table)
      end

      module_function

      # >>>
      #   1. Map -- For each character in the input, check if it has a mapping
      #      and, if so, replace it with its mapping.  This is described in
      #      section 3.
      #
      #   2. Normalize -- Possibly normalize the result of step 1 using Unicode
      #      normalization.  This is described in section 4.
      #
      #   3. Prohibit -- Check for any characters that are not allowed in the
      #      output.  If any are found, return an error.  This is described in
      #      section 5.
      #
      #   4. Check bidi -- Possibly check for right-to-left characters, and if
      #      any are found, make sure that the whole string satisfies the
      #      requirements for bidirectional strings.  If the string does not
      #      satisfy the requirements for bidirectional strings, return an
      #      error.  This is described in section 6.
      #
      #   The above steps MUST be performed in the order given to comply with
      #   this specification.
      #
      def stringprep(string,
                     maps:,
                     normalization:,
                     prohibited:,
                     **opts)
        string = string.encode("UTF-8") # also dups (and raises invalid encoding)
        map_tables!(string, *maps)                     if maps
        string.unicode_normalize!(normalization)       if normalization
        check_prohibited!(string, *prohibited, **opts) if prohibited
        string
      end

      def map_tables!(string, *tables)
        tables.each do |table|
          regexp, replacements = Tables::MAPPINGS.fetch(table)
          string.gsub!(regexp, replacements)
        end
        string
      end

      # Checks +string+ for any codepoint in +tables+. Raises a
      # ProhibitedCodepoint describing the first matching table.
      #
      # Also checks bidirectional characters, when <tt>bidi: true</tt>, which may
      # raise a BidiStringError.
      #
      # +profile+ is an optional string which will be added to any exception that
      # is raised (it does not affect behavior).
      def check_prohibited!(string,
                            *tables,
                            bidi: false,
                            unassigned: "A.1",
                            stored: false,
                            profile: nil)
        tables  = Tables::TITLES.keys.grep(/^C/) if tables.empty?
        tables |= [unassigned] if stored
        tables |= %w[C.8] if bidi
        table   = tables.find {|t|
          case t
          when String then Tables::REGEXPS.fetch(t).match?(string)
          when Regexp then t.match?(string)
          else raise ArgumentError, "only table names and regexps can be checked"
          end
        }
        if table
          raise ProhibitedCodepoint.new(
            table, string: string, profile: profile
          )
        end
        check_bidi!(string, profile: profile) if bidi
      end

      # Checks that +string+ obeys all of the "Bidirectional Characters"
      # requirements in RFC-3454, §6:
      #
      # * The characters in \StringPrep\[\"C.8\"] MUST be prohibited
      # * If a string contains any RandALCat character, the string MUST NOT
      #   contain any LCat character.
      # * If a string contains any RandALCat character, a RandALCat
      #   character MUST be the first character of the string, and a
      #   RandALCat character MUST be the last character of the string.
      #
      # This is usually combined with #check_prohibited!, so table "C.8" is only
      # checked when <tt>c_8: true</tt>.
      #
      # Raises either ProhibitedCodepoint or BidiStringError unless all
      # requirements are met.  +profile+ is an optional string which will be
      # added to any exception that is raised (it does not affect behavior).
      def check_bidi!(string, c_8: false, profile: nil)
        check_prohibited!(string, "C.8", profile: profile) if c_8
        if Tables::BIDI_FAILS_REQ2.match?(string)
          raise BidiStringError.new(
            Tables::BIDI_DESC_REQ2, string: string, profile: profile,
          )
        elsif Tables::BIDI_FAILS_REQ3.match?(string)
          raise BidiStringError.new(
            Tables::BIDI_DESC_REQ3, string: string, profile: profile,
          )
        end
      end

    end
  end
end
