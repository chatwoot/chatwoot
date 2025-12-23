require 'facebook/messenger/incoming/common'
require 'facebook/messenger/incoming/message'
require 'facebook/messenger/incoming/message_echo'
require 'facebook/messenger/incoming/message_request'
require 'facebook/messenger/incoming/delivery'
require 'facebook/messenger/incoming/postback'
require 'facebook/messenger/incoming/optin'
require 'facebook/messenger/incoming/read'
require 'facebook/messenger/incoming/account_linking'
require 'facebook/messenger/incoming/referral'
require 'facebook/messenger/incoming/payment'
require 'facebook/messenger/incoming/policy_enforcement'
require 'facebook/messenger/incoming/pass_thread_control'
require 'facebook/messenger/incoming/game_play'
require 'facebook/messenger/incoming/message_reaction'

module Facebook
  module Messenger
    #
    # Module Incoming parses and abstracts incoming requests from Messenger.
    #
    module Incoming
      #
      # @return [Hash] Hash containing facebook messenger events and its event
      #   handler classes.
      EVENTS = {
        'message' => Message,
        'delivery' => Delivery,
        'postback' => Postback,
        'optin' => Optin,
        'read' => Read,
        'account_linking' => AccountLinking,
        'referral' => Referral,
        'message_echo' => MessageEcho,
        'message_request' => MessageRequest,
        'payment' => Payment,
        'policy_enforcement' => PolicyEnforcement,
        'pass_thread_control' => PassThreadControl,
        'game_play' => GamePlay,
        'reaction' => MessageReaction
      }.freeze

      # Parse the given payload and create new object of class related
      #   to event in payload.
      #
      # @see https://developers.facebook.com/docs/messenger-platform/webhook-reference
      #
      # @raise [Facebook::Messenger::Incoming::UnknownPayload] if event is not
      #   registered in EVENTS constant
      #
      # @param [Hash] payload A Hash describing a payload from Facebook.
      #
      def self.parse(payload)
        return MessageEcho.new(payload) if payload_is_echo?(payload)

        EVENTS.each do |event, klass|
          return klass.new(payload) if payload.key?(event)
        end

        raise UnknownPayload, payload
      end

      #
      # Check if event is echo.
      #
      # @param [Hash] payload Request payload from facebook.
      #
      # @return [Boolean] If event is echo return true else false.
      #
      def self.payload_is_echo?(payload)
        payload.key?('message') && payload['message']['is_echo'] == true
      end

      #
      # Class UnknownPayload provides errors related to incoming messages.
      #
      class UnknownPayload < Facebook::Messenger::Error; end
    end
  end
end
