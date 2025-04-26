class Webhooks::FacebookCommentsJob < ApplicationJob
  queue_as :default
  
  def perform(payload)
    entries = payload['entry'] || []
    
    entries.each do |entry|
      process_entry(entry)
    end
  end
  
  private
  
  def process_entry(entry)
    changes = entry['changes'] || []
    page_id = entry['id']
    
    changes.each do |change|
      if change['field'] == 'feed' && change['value']['item'] == 'comment'
        process_comment(change['value'], page_id)
      end
    end
  end
  
  def process_comment(comment_data, page_id)
    # Tìm Facebook Page liên quan
    channel = Channel::FacebookPage.find_by(page_id: page_id)
    return unless channel
    
    # Lấy thông tin chi tiết về comment
    comment_id = comment_data['comment_id']
    post_id = comment_data['post_id']
    user_id = comment_data['from']['id']
    content = comment_data['message']
    
    # Kiểm tra xem comment có phải từ chính page không
    return if user_id == page_id
    
    # Tìm cấu hình webhook của người dùng
    config = FacebookCommentConfig.find_by(
      account_id: channel.account_id,
      inbox_id: channel.inbox.id,
      status: :active
    )
    
    return unless config
    
    # Gửi webhook đến người dùng
    send_webhook_to_user(config, {
      comment_id: comment_id,
      post_id: post_id,
      user_id: user_id,
      content: content,
      page_id: page_id,
      created_time: comment_data['created_time'],
      account_id: channel.account_id,
      inbox_id: channel.inbox.id
    })
  end
  
  def send_webhook_to_user(config, data)
    FacebookCommentWebhookJob.perform_later(config.id, data)
  end
end
