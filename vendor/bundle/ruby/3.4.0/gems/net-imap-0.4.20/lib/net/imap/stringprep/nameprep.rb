# frozen_string_literal: true

module Net
  class IMAP
    module StringPrep

      # Defined in RFC3491[https://tools.ietf.org/html/rfc3491], the +nameprep+
      # profile of "Stringprep" is:
      # >>>
      #   used by the IDNA protocol for preparing domain names; it is not
      #   designed for any other purpose.  It is explicitly not designed for
      #   processing arbitrary free text and SHOULD NOT be used for that
      #   purpose.
      #
      #   ...
      #
      #   This profile specifies prohibiting using the following tables...:
      #
      #   - C.1.2 (Non-ASCII space characters)
      #   - C.2.2 (Non-ASCII control characters)
      #   - C.3 (Private use characters)
      #   - C.4 (Non-character code points)
      #   - C.5 (Surrogate codes)
      #   - C.6 (Inappropriate for plain text)
      #   - C.7 (Inappropriate for canonical representation)
      #   - C.8 (Change display properties are deprecated)
      #   - C.9 (Tagging characters)
      #
      #   IMPORTANT NOTE: This profile MUST be used with the IDNA protocol.
      #   The IDNA protocol has additional prohibitions that are checked
      #   outside of this profile.
      module NamePrep

        # From RFC3491[https://www.rfc-editor.org/rfc/rfc3491.html] §10
        STRINGPREP_PROFILE = "nameprep"

        # From RFC3491[https://www.rfc-editor.org/rfc/rfc3491.html] §2
        UNASSIGNED_TABLE = "A.1"

        # From RFC3491[https://www.rfc-editor.org/rfc/rfc3491.html] §3
        MAPPING_TABLES = %w[B.1 B.2].freeze

        # From RFC3491[https://www.rfc-editor.org/rfc/rfc3491.html] §4
        NORMALIZATION = :nfkc

        # From RFC3491[https://www.rfc-editor.org/rfc/rfc3491.html] §5
        PROHIBITED_TABLES = %w[C.1.2 C.2.2 C.3 C.4 C.5 C.6 C.7 C.8 C.9].freeze

        # From RFC3491[https://www.rfc-editor.org/rfc/rfc3491.html] §6
        CHECK_BIDI = true

        module_function

        def nameprep(string, **opts)
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
