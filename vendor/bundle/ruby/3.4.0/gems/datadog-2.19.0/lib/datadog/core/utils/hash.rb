# frozen_string_literal: true

module Datadog
  module Core
    module Utils
      # Refinements for {Hash}.
      module Hash
        # This refinement ensures modern rubies are allowed to use newer,
        # simpler, and more performant APIs.
        module Refinement
          # Introduced in Ruby 2.4
          unless ::Hash.method_defined?(:compact)
            refine ::Hash do
              def compact
                reject { |_k, v| v.nil? }
              end
            end
          end

          # Introduced in Ruby 2.4
          unless ::Hash.method_defined?(:compact!)
            refine ::Hash do
              def compact!
                reject! { |_k, v| v.nil? }
              end
            end
          end
        end

        # A minimal {Hash} wrapper that provides case-insensitive access
        # to hash keys, without the overhead of copying the original hash.
        #
        # This class should be used when the original hash is short lived *and*
        # each hash key is only accesses a few times.
        # For other cases, create a copy of the original hash with the keys
        # normalized adequate to your use case.
        class CaseInsensitiveWrapper
          def initialize(hash)
            raise ArgumentError, "must be a hash, but was #{hash.class}: #{hash.inspect}" unless hash.is_a?(::Hash)

            @hash = hash
          end

          def [](key)
            return nil unless key.is_a?(::String)

            @hash.each do |k, value|
              return value if key.casecmp(k) == 0
            end

            nil
          end

          def key?(key)
            return false unless key.is_a?(::String)

            @hash.each_key do |k|
              return true if key.casecmp(k) == 0
            end

            false
          end

          def empty?
            @hash.empty?
          end

          def length
            @hash.length
          end

          def original_hash
            @hash
          end
        end
      end
    end
  end
end
