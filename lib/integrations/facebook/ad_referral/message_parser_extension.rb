# frozen_string_literal: true

module Integrations::Facebook::AdReferral
  module MessageParserExtension
    def referral
      @messaging['referral']&.deep_stringify_keys
    end
  end
end
