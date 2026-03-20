class Integrations::Slack::ChannelBuilder
  attr_reader :params, :channel

  def initialize(params)
    @params = params
  end

  def fetch_channels
    channels
  end

  def update_reference_id(reference_id)
    channel = find_channel(reference_id)
    return if channel.blank?

    slack_client.conversations_join(channel: channel[:id]) if channel[:is_private] == false
    @hook.update!(reference_id: channel[:id], settings: { channel_name: channel[:name] }, status: 'enabled')
    @hook
  end

  private

  def hook
    @hook ||= params[:hook]
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: hook.access_token)
  end

  def channels
    # Split channel fetching into separate API calls to avoid rate limiting issues.
    # Slack's API handles single-type requests (public OR private) much more efficiently
    # than mixed-type requests (public AND private). This approach eliminates rate limits
    # that occur when requesting both channel types simultaneously.
    channel_list = []

    # Step 1: Fetch all private channels in one call (expect very few)
    private_channels = fetch_channels_by_type('private_channel')
    channel_list.concat(private_channels)

    # Step 2: Fetch public channels with pagination
    public_channels = fetch_channels_by_type('public_channel')
    channel_list.concat(public_channels)
    channel_list
  end

  def fetch_channels_by_type(channel_type, limit: 1000)
    conversations_list = slack_client.conversations_list(types: channel_type, exclude_archived: true, limit: limit)
    channel_list = conversations_list.channels
    while conversations_list.response_metadata.next_cursor.present?
      conversations_list = slack_client.conversations_list(
        cursor: conversations_list.response_metadata.next_cursor,
        types: channel_type,
        exclude_archived: true,
        limit: limit
      )
      channel_list.concat(conversations_list.channels)
    end
    channel_list
  end

  def find_channel(reference_id)
    channels.find { |channel| channel['id'] == reference_id }
  end
end
