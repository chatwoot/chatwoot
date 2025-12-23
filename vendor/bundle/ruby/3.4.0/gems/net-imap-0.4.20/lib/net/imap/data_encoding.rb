# frozen_string_literal: true

require "date"
require "time"

require_relative "errors"

module Net
  class IMAP < Protocol

    # strftime/strptime format for an IMAP4 +date+, excluding optional dquotes.
    # Use via the encode_date and decode_date methods.
    #
    #   date            = date-text / DQUOTE date-text DQUOTE
    #   date-text       = date-day "-" date-month "-" date-year
    #
    #   date-day        = 1*2DIGIT
    #                       ; Day of month
    #   date-month      = "Jan" / "Feb" / "Mar" / "Apr" / "May" / "Jun" /
    #                     "Jul" / "Aug" / "Sep" / "Oct" / "Nov" / "Dec"
    #   date-year       = 4DIGIT
    STRFDATE = "%d-%b-%Y"

    # strftime/strptime format for an IMAP4 +date-time+, including dquotes.
    # See the encode_datetime and decode_datetime methods.
    #
    #   date-time       = DQUOTE date-day-fixed "-" date-month "-" date-year
    #                     SP time SP zone DQUOTE
    #
    #   date-day-fixed  = (SP DIGIT) / 2DIGIT
    #                       ; Fixed-format version of date-day
    #   date-month      = "Jan" / "Feb" / "Mar" / "Apr" / "May" / "Jun" /
    #                     "Jul" / "Aug" / "Sep" / "Oct" / "Nov" / "Dec"
    #   date-year       = 4DIGIT
    #   time            = 2DIGIT ":" 2DIGIT ":" 2DIGIT
    #                       ; Hours minutes seconds
    #   zone            = ("+" / "-") 4DIGIT
    #                       ; Signed four-digit value of hhmm representing
    #                       ; hours and minutes east of Greenwich (that is,
    #                       ; the amount that the given time differs from
    #                       ; Universal Time).  Subtracting the timezone
    #                       ; from the given time will give the UT form.
    #                       ; The Universal Time zone is "+0000".
    #
    # Note that Time.strptime <tt>"%d"</tt> flexibly parses either space or zero
    # padding.  However, the DQUOTEs are *not* optional.
    STRFTIME = '"%d-%b-%Y %H:%M:%S %z"'

    # Decode a string from modified UTF-7 format to UTF-8.
    #
    # UTF-7 is a 7-bit encoding of Unicode [UTF7].  IMAP uses a
    # slightly modified version of this to encode mailbox names
    # containing non-ASCII characters; see [IMAP] section 5.1.3.
    #
    # Net::IMAP does _not_ automatically encode and decode
    # mailbox names to and from UTF-7.
    def self.decode_utf7(s)
      return s.gsub(/&([A-Za-z0-9+,]+)?-/n) {
        if base64 = $1
          (base64.tr(",", "/") + "===").unpack1("m").encode(Encoding::UTF_8, Encoding::UTF_16BE)
        else
          "&"
        end
      }
    end

    # Encode a string from UTF-8 format to modified UTF-7.
    def self.encode_utf7(s)
      return s.gsub(/(&)|[^\x20-\x7e]+/) {
        if $1
          "&-"
        else
          base64 = [$&.encode(Encoding::UTF_16BE)].pack("m0")
          "&" + base64.delete("=").tr("/", ",") + "-"
        end
      }.force_encoding("ASCII-8BIT")
    end

    # Formats +time+ as an IMAP4 date.
    def self.encode_date(date)
      date.to_date.strftime STRFDATE
    end

    # :call-seq: decode_date(string) -> Date
    #
    # Decodes +string+ as an IMAP formatted "date".
    #
    # Double quotes are optional.  Day of month may be padded with zero or
    # space.  See STRFDATE.
    def self.decode_date(string)
      string = string.delete_prefix('"').delete_suffix('"')
      Date.strptime(string, STRFDATE)
    end

    # :call-seq: encode_datetime(time) -> string
    #
    # Formats +time+ as an IMAP4 date-time.
    def self.encode_datetime(time)
      time.to_datetime.strftime STRFTIME
    end

    # :call-seq: decode_datetime(string) -> DateTime
    #
    # Decodes +string+ as an IMAP4 formatted "date-time".
    #
    # NOTE: Although double-quotes are not optional in the IMAP grammar,
    # Net::IMAP currently parses "date-time" values as "quoted" strings and this
    # removes the quotation marks.  To be useful for strings which have already
    # been parsed as a quoted string, this method makes double-quotes optional.
    #
    # See STRFTIME.
    def self.decode_datetime(string)
      unless string.start_with?(?") && string.end_with?(?")
        string = '"%s"' % [string]
      end
      DateTime.strptime(string, STRFTIME)
    end

    # :call-seq: decode_time(string) -> Time
    #
    # Decodes +string+ as an IMAP4 formatted "date-time".
    #
    # Same as +decode_datetime+, but returning a Time instead.
    def self.decode_time(string)
      unless string.start_with?(?") && string.end_with?(?")
        string = '"%s"' % [string]
      end
      Time.strptime(string, STRFTIME)
    end

    class << self
      alias encode_time     encode_datetime
      alias format_date     encode_date
      alias format_time     encode_time
      alias parse_date      decode_date
      alias parse_datetime  decode_datetime
      alias parse_time      decode_time

      # alias format_datetime encode_datetime  # n.b: this is overridden below...
    end

    # DEPRECATED:: The original version returned incorrectly formatted strings.
    #              Strings returned by encode_datetime or format_time use the
    #              correct IMAP4rev1 syntax for "date-time".
    #
    # This invalid format has been temporarily retained for backward
    # compatibility.  A future release will change this method to return the
    # correct format.
    def self.format_datetime(time)
      warn("#{self}.format_datetime incorrectly formats IMAP date-time. " \
           "Convert to #{self}.encode_datetime or #{self}.format_time instead.",
           uplevel: 1, category: :deprecated)
      time.strftime("%d-%b-%Y %H:%M %z")
    end

    # Common validators of number and nz_number types
    module NumValidator # :nodoc
      module_function

      # Check is passed argument valid 'number' in RFC 3501 terminology
      def valid_number?(num)
        # [RFC 3501]
        # number          = 1*DIGIT
        #                    ; Unsigned 32-bit integer
        #                    ; (0 <= n < 4,294,967,296)
        num >= 0 && num < 4294967296
      end

      # Check is passed argument valid 'nz_number' in RFC 3501 terminology
      def valid_nz_number?(num)
        # [RFC 3501]
        # nz-number       = digit-nz *DIGIT
        #                    ; Non-zero unsigned 32-bit integer
        #                    ; (0 < n < 4,294,967,296)
        num != 0 && valid_number?(num)
      end

      # Check is passed argument valid 'mod_sequence_value' in RFC 4551 terminology
      def valid_mod_sequence_value?(num)
        # mod-sequence-value  = 1*DIGIT
        #                        ; Positive unsigned 64-bit integer
        #                        ; (mod-sequence)
        #                        ; (1 <= n < 18,446,744,073,709,551,615)
        num >= 1 && num < 18446744073709551615
      end

      # Ensure argument is 'number' or raise DataFormatError
      def ensure_number(num)
        return if valid_number?(num)

        msg = "number must be unsigned 32-bit integer: #{num}"
        raise DataFormatError, msg
      end

      # Ensure argument is 'nz_number' or raise DataFormatError
      def ensure_nz_number(num)
        return if valid_nz_number?(num)

        msg = "nz_number must be non-zero unsigned 32-bit integer: #{num}"
        raise DataFormatError, msg
      end

      # Ensure argument is 'mod_sequence_value' or raise DataFormatError
      def ensure_mod_sequence_value(num)
        return if valid_mod_sequence_value?(num)

        msg = "mod_sequence_value must be unsigned 64-bit integer: #{num}"
        raise DataFormatError, msg
      end

    end

  end
end
