class Zalo::Messages::AttachmentService < Zalo::Messages::BaseService

  private

  def message_content
    nil
  end

  def content_type
    :text
  end

  def process_attachments
    return unless need_process_attachments?

    message_attachments.each do |attachment|
      @message.attachments.find_or_initialize_by(
        account_id: account.id,
        external_url: attachment.dig(:payload, :url) || attachment.dig(:payload, :thumbnail),
        file_type: get_filetype(attachment),
        meta: { original: attachment },
      )
    end
  rescue StandardError => e
    Rails.logger.error("Failed to process attachments: #{e.message}")
    raise e
  end

  def get_filetype(attachment)
    filetype = [attachment[:type].presence, attachment.dig(:payload, :type).presence].compact.join('.')
    {
      'file.mp4' => 'video',
      'file.gif' => 'image',
      'gif' => 'image',
      'image' => 'image',
      'audio' => 'audio',
    }[filetype] || 'file'
  end

  def need_process_attachments?
    message_attachments.present? && @message.attachments.empty?
  end
end

# {"event_name"=>"oa_send_file", "app_id"=>"102719276611582260", "sender"=>{"admin_id"=>"8309393969855402319", "id"=>"1423847451268726170"}, "recipient"=>{"id"=>"8309393969855402319"}, "message"=>{"attachments"=>[{"payload"=>{"size"=>"24165", "name"=>"20250625_084851.log", "checksum"=>"2d018db1ed7ec464a85709c9c580d343", "type"=>"log", "url"=>"https://ot51.dlfl.vn/13e0e523d31972472b08/8536413009756936687"}, "type"=>"file"}], "msg_id"=>"f3af2263f0673c3f6570"}, "timestamp"=>"1751272409784", "user_id_by_app"=>"7300442764876318465", "controller"=>"webhooks/zalo", "action"=>"process_payload", "zalo"=>{"event_name"=>"oa_send_file", "app_id"=>"102719276611582260", "sender"=>{"admin_id"=>"8309393969855402319", "id"=>"1423847451268726170"}, "recipient"=>{"id"=>"8309393969855402319"}, "message"=>{"attachments"=>[{"payload"=>{"size"=>"24165", "name"=>"20250625_084851.log", "checksum"=>"2d018db1ed7ec464a85709c9c580d343", "type"=>"log", "url"=>"https://ot51.dlfl.vn/13e0e523d31972472b08/8536413009756936687"}, "type"=>"file"}], "msg_id"=>"f3af2263f0673c3f6570"}, "timestamp"=>"1751272409784", "user_id_by_app"=>"7300442764876318465"}}
