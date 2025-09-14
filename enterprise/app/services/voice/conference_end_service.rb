module Voice
  class ConferenceEndService
    pattr_initialize [:conversation!]

    def perform
      # Compute conference friendly name from readable conversation ID
      name = "conf_account_#{conversation.account_id}_conv_#{conversation.display_id}"

      cfg = conversation.inbox.channel.provider_config_hash
      client = ::Twilio::REST::Client.new(cfg['account_sid'], cfg['auth_token'])
      # Find all in-progress conferences matching this friendly name and end them
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
