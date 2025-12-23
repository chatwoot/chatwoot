# frozen_string_literal: true

require 'aws-sdk-sns'

module Aws
  module ActionMailbox
    module SES
      # @api private
      class SNSMessageVerifier
        class << self
          def verifier
            @verifier ||= Aws::SNS::MessageVerifier.new
          end
        end
      end
    end
  end
end
