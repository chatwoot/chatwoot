module Voice
  module Conference
    class EndService
      pattr_initialize [:conversation!]

      def perform
        name = Voice::Conference::Name.for(conversation)

        cfg = conversation.inbox.channel.provider_config_hash
        account_sid = cfg['account_sid']
        auth_token = cfg['auth_token']
        return if account_sid.blank? || auth_token.blank?

        client = ::Twilio::REST::Client.new(account_sid, auth_token)
        client.conferences.list(friendly_name: name, status: 'in-progress').each do |conf|
          begin
            client.conferences(conf.sid).update(status: 'completed')
          rescue StandardError => e
            Rails.logger.error("VOICE_CONFERENCE_END_UPDATE_ERROR conf=#{conf.sid} error=#{e.class}: #{e.message}")
          end
        end
      rescue StandardError => e
        Rails.logger.error(
          "VOICE_CONFERENCE_END_ERROR account=#{conversation.account_id} conversation=#{conversation.display_id} name=#{name} error=#{e.class}: #{e.message}"
        )
      end
    end
  end
end
