class Whatsapp::ContactIdsFinder
  def perform
    ContactInbox.joins(:inbox)
                .joins(<<~SQL.squish)
                  LEFT JOIN channel_twilio_sms
                    ON channel_twilio_sms.id = inboxes.channel_id
                    AND inboxes.channel_type = 'Channel::TwilioSms'
                SQL
                .where(
                  'inboxes.channel_type = :cloud OR (inboxes.channel_type = :twilio AND channel_twilio_sms.medium = :whatsapp)',
                  cloud: 'Channel::Whatsapp', twilio: 'Channel::TwilioSms', whatsapp: Channel::TwilioSms.media.fetch('whatsapp')
                )
                .select(:contact_id)
  end
end
