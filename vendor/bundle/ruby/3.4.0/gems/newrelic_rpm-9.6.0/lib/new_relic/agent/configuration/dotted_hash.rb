# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Configuration
      class DottedHash < ::Hash
        def initialize(hash, keep_nesting = false)
          # Add the hash keys to our collection explicitly so they survive the
          # dot flattening.  This is typical for full config source instances,
          # but not for uses of DottedHash serializing for transmission.
          self.merge!(hash) if keep_nesting

          self.merge!(dot_flattened(hash))
          DottedHash.symbolize(self)
        end

        def inspect
          "#<#{self.class.name}:#{object_id} #{super}>"
        end

        def to_hash
          {}.replace(self)
        end

        def self.symbolize(hash)
          hash.keys.each do |key|
            hash[key.to_sym] = hash.delete(key)
          end
        end

        protected

        # turns {'a' => {'b' => 'c'}} into {'a.b' => 'c'}
        def dot_flattened(nested_hash, names = [], result = {})
          nested_hash.each do |key, val|
            next if val.nil?

            if val.respond_to?(:has_key?)
              dot_flattened(val, names + [key], result)
            else
              result[(names + [key]).join('.')] = val
            end
          end
          result
        end
      end
    end
  end
end
