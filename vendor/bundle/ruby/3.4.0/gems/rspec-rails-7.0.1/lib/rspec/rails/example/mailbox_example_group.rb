module RSpec
  module Rails
    # @api public
    # Container module for mailbox spec functionality.
    module MailboxExampleGroup
      extend ActiveSupport::Concern

      if RSpec::Rails::FeatureCheck.has_action_mailbox?
        require 'action_mailbox/test_helper'
        extend ::ActionMailbox::TestHelper

        # @private
        def self.create_inbound_email(arg)
          case arg
          when Hash
            create_inbound_email_from_mail(**arg)
          else
            create_inbound_email_from_source(arg.to_s)
          end
        end
      else
        def self.create_inbound_email(_arg)
          raise "Could not load ActionMailer::TestHelper"
        end
      end

      class_methods do
        # @private
        def mailbox_class
          described_class
        end
      end

      included do
        subject { described_class }
      end

      # @api public
      # Passes if the inbound email was delivered
      #
      # @example
      #       inbound_email = process(args)
      #       expect(inbound_email).to have_been_delivered
      def have_been_delivered
        satisfy('have been delivered', &:delivered?)
      end

      # @api public
      # Passes if the inbound email bounced during processing
      #
      # @example
      #       inbound_email = process(args)
      #       expect(inbound_email).to have_bounced
      def have_bounced
        satisfy('have bounced', &:bounced?)
      end

      # @api public
      # Passes if the inbound email failed to process
      #
      # @example
      #       inbound_email = process(args)
      #       expect(inbound_email).to have_failed
      def have_failed
        satisfy('have failed', &:failed?)
      end

      # Process an inbound email message directly, bypassing routing.
      #
      # @param message [Hash, Mail::Message] a mail message or hash of
      #   attributes used to build one
      # @return [ActionMailbox::InboundMessage]
      def process(message)
        MailboxExampleGroup.create_inbound_email(message).tap do |mail|
          self.class.mailbox_class.receive(mail)
        end
      end
    end
  end
end
