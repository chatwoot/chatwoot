module Facebook
  module Messenger
    module Incoming
      #
      # Message class represents an incoming Facebook Messenger message event.
      # @see https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/messages
      #
      class Message
        include Facebook::Messenger::Incoming::Common

        #
        # @return [Array] Supported attachments for message.
        ATTACHMENT_TYPES = %w[image audio video file location fallback].freeze

        #
        # Function returns unique id of message
        # @see https://developers.facebook.com/docs/messenger-platform/reference/webhook-events/messages
        #   Info about received message format.
        #
        # @return [String] Unique id of message.
        #
        def id
          @messaging['message']['mid']
        end

        def seq
          @messaging['message']['seq']
        end

        #
        # Function returns text of message
        #
        # @return [String] Text of message.
        #
        def text
          @messaging['message']['text']
        end

        #
        # Whether message is echo or not?
        #
        # @return [Boolean] If message is echo return true else false.
        #
        def echo?
          @messaging['message']['is_echo']
        end

        #
        # Function returns array containing attachment data
        # @see https://developers.facebook.com/docs/messenger-platform/send-messages#sending_attachments
        #   More info about attachments.
        #
        # @return [Array] Attachment data.
        #
        def attachments
          @messaging['message']['attachments']
        end

        #
        # If facebook messenger built-in NLP is enabled, message will
        #   contain 'nlp' key in response.
        # @see https://developers.facebook.com/docs/messenger-platform/built-in-nlp
        #   More information about built-in NLP.
        #
        #
        # @return [Hash] NLP information about message.
        #
        def nlp
          @messaging['message']['nlp']
        end

        #
        # Function return app id from message.
        #
        # @return [String] App ID.
        #
        def app_id
          @messaging['message']['app_id']
        end

        #
        # This meta programming defines function for
        #   every attachment type to check whether the attachment
        #   in message is of defined type or not.
        #
        ATTACHMENT_TYPES.each do |attachment_type|
          define_method "#{attachment_type}_attachment?" do
            attachment_type?(attachment_type)
          end
        end

        #
        # Get the type of attachment in message.
        #
        # @return [String] Attachment type.
        #
        def attachment_type
          return if attachments.nil?

          attachments.first['type']
        end

        #
        # Get the URL of attachment in message.
        # URL is only available for attachments of type image/audio/video/file.
        #
        # @return [String] URL of attachment.
        #
        def attachment_url
          return if attachments.nil?
          return unless %w[image audio video file].include? attachment_type

          attachments.first['payload']['url']
        end

        #
        # Get the location coordinates if attachment type is 'location'.
        # @example [LATITUDE, LONGITUDE]
        #
        # @return [Array] Location coordinates.
        #
        def location_coordinates
          return [] unless attachment_type?('location')

          coordinates_data = attachments.first['payload']['coordinates']
          [coordinates_data['lat'], coordinates_data['long']]
        end

        #
        # Get the payload of quick reply.
        # @see https://developers.facebook.com/docs/messenger-platform/send-messages/quick-replies
        #   More info about quick reply.
        #
        # @return [String] Payload string.
        #
        def quick_reply
          return unless @messaging['message']['quick_reply']

          @messaging['message']['quick_reply']['payload']
        end

        # @private
        private

        #
        # Check if attachment in message is of given type or not?
        #
        # @param [String] attachment_type Attachment type
        #
        # @return [Boolean] If type of attachment in message
        #   and provided attachment type are same then return true else false.
        #
        def attachment_type?(attachment_type)
          !attachments.nil? && attachments.first['type'] == attachment_type
        end
      end
    end
  end
end
