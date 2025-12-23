module RSpec
  module Rails
    module Matchers
      # Namespace for various implementations of ActionMailbox features
      #
      # @api private
      module ActionMailbox
        # @private
        class Base < RSpec::Rails::Matchers::BaseMatcher
          private

          def create_inbound_email(message)
            RSpec::Rails::MailboxExampleGroup.create_inbound_email(message)
          end
        end

        # @private
        class ReceiveInboundEmail < Base
          def initialize(message)
            super()

            @inbound_email = create_inbound_email(message)
          end

          if defined?(::ApplicationMailbox) && ::ApplicationMailbox.router.respond_to?(:mailbox_for)
            def matches?(mailbox)
              @mailbox  = mailbox
              @receiver = ApplicationMailbox.router.mailbox_for(inbound_email)

              @receiver == @mailbox
            end
          else
            def matches?(mailbox)
              @mailbox  = mailbox
              @receiver = ApplicationMailbox.router.send(:match_to_mailbox, inbound_email)

              @receiver == @mailbox
            end
          end

          def failure_message
            "expected #{describe_inbound_email} to route to #{mailbox}".tap do |msg|
              if receiver
                msg << ", but routed to #{receiver} instead"
              end
            end
          end

          def failure_message_when_negated
            "expected #{describe_inbound_email} not to route to #{mailbox}"
          end

          private

          attr_reader :inbound_email, :mailbox, :receiver

          def describe_inbound_email
            "mail to #{inbound_email.mail.to.to_sentence}"
          end
        end
      end

      # @api public
      # Passes if the given inbound email would be routed to the subject inbox.
      #
      # @param message [Hash, Mail::Message] a mail message or hash of
      #   attributes used to build one
      def receive_inbound_email(message)
        ActionMailbox::ReceiveInboundEmail.new(message)
      end
    end
  end
end
