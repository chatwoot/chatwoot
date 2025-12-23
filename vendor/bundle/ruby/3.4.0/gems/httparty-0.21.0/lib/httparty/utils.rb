# frozen_string_literal: true

module HTTParty
  module Utils
    def self.stringify_keys(hash)
      return hash.transform_keys(&:to_s) if hash.respond_to?(:transform_keys)

      hash.each_with_object({}) do |(key, value), new_hash|
        new_hash[key.to_s] = value
      end
    end
  end
end
