# frozen_string_literal: true

module Net
  class IMAP
    module StringPrep

      # Defined in RFC-4505[https://tools.ietf.org/html/rfc4505] §3, The +trace+
      # profile of \StringPrep is used by the +ANONYMOUS+ \SASL mechanism.
      module Trace

        # Defined in RFC-4505[https://tools.ietf.org/html/rfc4505] §3.
        STRINGPREP_PROFILE = "trace"

        # >>>
        #   The character repertoire of this profile is Unicode 3.2 [Unicode].
        UNASSIGNED_TABLE = "A.1"

        # >>>
        #   No mapping is required by this profile.
        MAPPING_TABLES = nil

        # >>>
        #   No Unicode normalization is required by this profile.
        NORMALIZATION = nil

        # From RFC-4505[https://tools.ietf.org/html/rfc4505] §3, The "trace"
        # Profile of "Stringprep":
        # >>>
        #   Characters from the following tables of [StringPrep] are prohibited:
        #
        #   - C.2.1 (ASCII control characters)
        #   - C.2.2 (Non-ASCII control characters)
        #   - C.3 (Private use characters)
        #   - C.4 (Non-character code points)
        #   - C.5 (Surrogate codes)
        #   - C.6 (Inappropriate for plain text)
        #   - C.8 (Change display properties are deprecated)
        #   - C.9 (Tagging characters)
        #
        #   No additional characters are prohibited.
        PROHIBITED_TABLES = %w[C.2.1 C.2.2 C.3 C.4 C.5 C.6 C.8 C.9].freeze

        # >>>
        #   This profile requires bidirectional character checking per Section 6
        #   of [StringPrep].
        CHECK_BIDI = true

        module_function

        # From RFC-4505[https://tools.ietf.org/html/rfc4505] §3, The "trace"
        # Profile of "Stringprep":
        # >>>
        #   The character repertoire of this profile is Unicode 3.2 [Unicode].
        #
        #   No mapping is required by this profile.
        #
        #   No Unicode normalization is required by this profile.
        #
        #   The list of unassigned code points for this profile is that provided
        #   in Appendix A of [StringPrep].  Unassigned code points are not
        #   prohibited.
        #
        #   Characters from the following tables of [StringPrep] are prohibited:
        #   (documented on PROHIBITED_TABLES)
        #
        #   This profile requires bidirectional character checking per Section 6
        #   of [StringPrep].
        def stringprep_trace(string, **opts)
          StringPrep.stringprep(
            string,
            unassigned:    UNASSIGNED_TABLE,
            maps:          MAPPING_TABLES,
            prohibited:    PROHIBITED_TABLES,
            normalization: NORMALIZATION,
            bidi:          CHECK_BIDI,
            profile:       STRINGPREP_PROFILE,
            **opts,
          )
        end

      end

    end
  end
end
