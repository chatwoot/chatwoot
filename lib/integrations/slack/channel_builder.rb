class Integrations::Slack::ChannelBuilder
  attr_reader :params, :channel

  def initialize(params)
    @params = params
  end

  def perform
    find_or_create_channel
    update_reference_id
  end

  private

  def hook
    @hook ||= params[:hook]
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: hook.access_token)
  end

  def find_or_create_channel
    exisiting_channel = slack_client.conversations_list.channels.find { |channel| channel['name'] == params[:channel] }
    @channel = exisiting_channel || slack_client.conversations_create(name: params[:channel])['channel']
  end

  def update_reference_id
    slack_client.conversations_join(channel: channel[:id])
    @hook.update(reference_id: channel[:id])
  end
end
