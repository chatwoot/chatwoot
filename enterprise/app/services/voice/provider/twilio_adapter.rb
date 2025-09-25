module Voice
  module Provider
    class TwilioAdapter
      def initialize(channel)
        @channel = channel
      end

      def initiate_call(to:, conference_sid: nil, agent_id: nil)
        cfg = @channel.provider_config_hash

        host = ENV.fetch('FRONTEND_URL')
        phone_digits = @channel.phone_number.delete_prefix('+')
        callback_url = "#{host}/twilio/voice/call/#{phone_digits}"

        params = {
          from: @channel.phone_number,
          to: to,
          url: callback_url,
          status_callback: "#{host}/twilio/voice/status/#{phone_digits}",
          status_callback_event: %w[initiated ringing answered completed failed busy no-answer canceled],
          status_callback_method: 'POST'
        }

        call = twilio_client(cfg).calls.create(**params)

        {
          provider: 'twilio',
          call_sid: call.sid,
          status: call.status,
          call_direction: 'outbound',
          requires_agent_join: true,
          agent_id: agent_id,
          conference_sid: conference_sid
        }
      end

      private

      def twilio_client(config)
        Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
      end
    end
  end
end

