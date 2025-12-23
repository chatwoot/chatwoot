# frozen_string_literal: true

module Twilio
  class Values
    def self.of(hash)
      hash.delete_if { |_, v| v.eql?(:unset) }
    end
  end
end
