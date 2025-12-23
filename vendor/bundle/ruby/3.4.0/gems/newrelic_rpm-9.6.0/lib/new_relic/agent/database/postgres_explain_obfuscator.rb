# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Database
      module PostgresExplainObfuscator
        extend self

        # Note that this regex can't be shared with the ones in the
        # Database::Obfuscator class because here we don't look for
        # backslash-escaped strings.
        QUOTED_STRINGS_REGEX = /'(?:[^']|'')*'|"(?:[^"]|"")*"/
        LABEL_LINE_REGEX = /^([^:\n]*:\s+).*$/.freeze

        def obfuscate(explain)
          # First, we replace all single-quoted strings.
          # This is necessary in order to deal with multi-line string constants
          # embedded in the explain output.
          #
          # Note that we look for both single or double quotes but do not
          # replace double quotes in order to avoid accidentally latching onto a
          # single quote character embedded within a quoted identifier (such as
          # a table name).
          #
          # Note also that we make no special provisions for backslash-escaped
          # single quotes (\') because these are canonicalized to two single
          # quotes ('') in the explain output.
          explain.gsub!(QUOTED_STRINGS_REGEX) do |match|
            match.start_with?('"') ? match : '?'
          end

          # Now, mask anything after the first colon (:).
          # All parts of the query that can appear in the explain output are
          # prefixed with "<label>: ", so we want to preserve the label, but
          # remove the rest of the line.
          explain.gsub!(LABEL_LINE_REGEX, '\1?')
          explain
        end
      end
    end
  end
end
