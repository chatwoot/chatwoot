require_relative 'server'

module Facebook
  module Messenger
    # Server rescuing all errors sending the backtrace back to the chat
    # FOR DEVELOPPING PURPOSE
    class ServerNoError < Server
      SCREAMING_FACE = "\xF0\x9F\x98\xB1".freeze
      MAX_MESSAGE_LENGTH = 639

      def call(env)
        super
      rescue Exception => e # rubocop:disable Lint/RescueException
        send(SCREAMING_FACE)
        send(e.inspect)
        send(e.backtrace.join("\n")[0..MAX_MESSAGE_LENGTH - 3] + '...')

        @response.status = 200
        @response.finish
      end

      private

      def sender
        parsed_body['entry'][0]['messaging'][0]['sender']
      end

      def send(text)
        Bot.deliver({
                      recipient: sender,
                      message: { text: text }
                    }, access_token: ENV['ACCESS_TOKEN'])
      end
    end
  end
end
