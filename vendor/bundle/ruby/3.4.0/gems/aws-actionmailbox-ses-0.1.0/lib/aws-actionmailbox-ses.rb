# frozen_string_literal: true

require_relative 'aws/action_mailbox/ses/engine'
require_relative 'aws/action_mailbox/ses/s3_client'
require_relative 'aws/action_mailbox/ses/sns_message_verifier'
require_relative 'aws/action_mailbox/ses/sns_notification'

module Aws
  module ActionMailbox
    module SES
      VERSION = File.read(File.expand_path('../VERSION', __dir__)).strip
    end
  end
end
