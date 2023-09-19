class Integrations::Slack::ChannelBuilder
  attr_reader :params, :channel

  def initialize(params)
    @params = params
  end

  def fetch_channels
    channels
  end

  def update(reference_id)
    update_reference_id(reference_id)
  end

  private

  def hook
    @hook ||= params[:hook]
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: hook.access_token)
  end

  def channels
    conversations_list = slack_client.conversations_list(types: 'public_channel, private_channel', exclude_archived: true)
    channel_list = conversations_list.channels
    while conversations_list.response_metadata.next_cursor.present?
      conversations_list = slack_client.conversations_list(cursor: conversations_list.response_metadata.next_cursor)
      channel_list.concat(conversations_list.channels)
    end
    channel_list
  end

  def find_channel(reference_id)
    channels.find { |channel| channel['id'] == reference_id }
  end

  def update_reference_id(reference_id)
    channel = find_channel(reference_id)
    return if channel.blank?

    slack_client.conversations_join(channel: channel[:id]) if channel[:is_private] == false
    @hook.update!(reference_id: channel[:id], settings: { channel_name: channel[:name] }, status: 'enabled')
    @hook
  end
end
