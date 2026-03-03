class SuperAdmin::Api::ConnectionHealthController < SuperAdmin::ApplicationController
  def index
    inboxes = Inbox.includes(:account, :channel).where(channel_type: ['Channel::Whatsapp', 'Channel::Api'])

    render json: inboxes.map { |inbox| serialize_inbox(inbox) }
  end

  private

  def serialize_inbox(inbox)
    channel = inbox.channel

    {
      account_name: inbox.account.name,
      inbox_name: inbox.name,
      channel_type: format_channel_type(inbox, channel),
      phone_number: channel.try(:phone_number) || '-',
      status: connection_status(channel),
      last_error: channel.try(:provider_config)&.dig('last_error') || ''
    }
  end

  def format_channel_type(inbox, channel)
    if inbox.channel_type == 'Channel::Whatsapp' && channel.try(:provider) == 'whatsapp_cloud'
      'WhatsApp Cloud API'
    else
      inbox.channel.name
    end
  end

  def connection_status(channel)
    if channel.respond_to?(:reauthorization_required?) && channel.reauthorization_required?
      'disconnected'
    elsif channel.respond_to?(:authorization_error_count) && channel.authorization_error_count.to_i.positive?
      'error'
    else
      'connected'
    end
  end
end
