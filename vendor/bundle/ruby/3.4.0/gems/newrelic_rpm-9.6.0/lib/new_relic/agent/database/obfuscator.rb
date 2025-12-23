# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/database/obfuscation_helpers'

module NewRelic
  module Agent
    module Database
      class Obfuscator
        include Singleton
        include ObfuscationHelpers

        attr_reader :obfuscator

        QUERY_TOO_LARGE_MESSAGE = 'Query too large (over 16k characters) to safely obfuscate'.freeze
        ELLIPSIS = '...'.freeze

        def initialize
          reset
        end

        def reset
          @obfuscator = method(:default_sql_obfuscator)
        end

        # Sets the sql obfuscator used to clean up sql when sending it
        # to the server. Possible types are:
        #
        # :before => sets the block to run before the existing
        # obfuscators
        #
        # :after => sets the block to run after the existing
        # obfuscator(s)
        #
        # :replace => removes the current obfuscator and replaces it
        # with the provided block
        def set_sql_obfuscator(type, &block)
          if type == :before
            @obfuscator = NewRelic::ChainedCall.new(block, @obfuscator)
          elsif type == :after
            @obfuscator = NewRelic::ChainedCall.new(@obfuscator, block)
          elsif type == :replace
            @obfuscator = block
          else
            fail "unknown sql_obfuscator type #{type}"
          end
        end

        def default_sql_obfuscator(sql)
          stmt = sql.kind_of?(Statement) ? sql : Statement.new(sql)

          if stmt.sql.end_with?(ELLIPSIS)
            return QUERY_TOO_LARGE_MESSAGE
          end

          obfuscate(stmt.sql, stmt.adapter).to_s
        end
      end
    end
  end
end
