class WechatKf::SyncMessagesJob < ApplicationJob
  queue_as :low

  def perform(integration_id, open_kfid, token, queued_at)
    integration = WechatKfIntegration.find(integration_id)
    channel = integration.channels.find_by!(open_kfid: open_kfid)
    client = WechatKf::ApiClient.new(integration)

    loop do
      break unless sync_page(channel, client, token, queued_at)
    end
  end

  private

  def sync_page(channel, client, token, queued_at)
    channel.with_lock do
      current_token = Time.current.to_i - queued_at < 9.minutes ? token : nil
      response = client.sync_messages(open_kfid: channel.open_kfid, token: current_token, cursor: channel.sync_cursor)
      response.fetch('msg_list').each { |entry| WechatKf::IncomingMessageService.new(channel).perform(entry) }
      next_cursor = response.fetch('next_cursor')
      cursor_stalled = next_cursor.blank? || (response['has_more'] == 1 && next_cursor == channel.sync_cursor)
      raise CustomExceptions::WechatKfApiError, 'WeChat Customer Service cursor did not advance' if cursor_stalled

      channel.update!(sync_cursor: next_cursor)
      response['has_more'] == 1
    end
  end
end
