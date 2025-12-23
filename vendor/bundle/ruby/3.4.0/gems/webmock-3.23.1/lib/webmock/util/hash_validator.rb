# frozen_string_literal: true

module WebMock
  class HashValidator
    def initialize(hash)
      @hash = hash
    end

    #This code is based on https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/hash/keys.rb
    def validate_keys(*valid_keys)
      valid_keys.flatten!
      @hash.each_key do |k|
        unless valid_keys.include?(k)
          raise ArgumentError.new("Unknown key: #{k.inspect}. Valid keys are: #{valid_keys.map(&:inspect).join(', ')}")
        end
      end
    end
  end
end
