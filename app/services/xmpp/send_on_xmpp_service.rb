require 'common_marker/xep0393_renderer'

class Xmpp::SendOnXmppService < Base::SendOnChannelService
  def initialize(*)
    super
    @connections = {}
  end

  def start_worker_thread
    thread = Thread.new do
      Channel::Xmpp.all.each { |channel| connect_channel(channel) }

      reprocess_in_progress

      loop do
        json = ::Redis::Alfred.brpoplpush('xmpp_outbound', 'xmpp_outbound_in_progress')
        item = JSON.parse(json)
        connection = @connections[item['channel_id']]

        if item['_channel_update']
          connection&.shutdown
          connection = @connections[item['channel_id']] = nil
        end

        process_oubound_item(item, connection)
        ::Redis::Alfred.lrem('xmpp_outbound_in_progress', json)
      end
    end

    thread.abort_on_exception = true
    thread
  end

  def connect_channel(channel)
    return unless channel

    @connections[channel.id] = connection = Xmpp::Connection.new(channel)
    EM.next_tick { connection.run }

    connection
  end

  def reprocess_in_progress
    resume = true
    while resume
      resume = ::Redis::Alfred.rpoplpush(
        'xmpp_outbound_in_progress',
        'xmpp_outbound'
      )
    end
  end

  def process_oubound_item(item, connection)
    connection ||= connect_channel(Channel::Xmpp.find_by(id: item['channel_id']))
    return unless item['to']

    unless connection&.connected?
      ::Redis::Alfred.rpush('xmpp_outbound', item.to_json)
      return
    end

    connection << message_for_item(item)
  end

  def message_for_item(item)
    Blather::Stanza::Message.new.tap do |m|
      m.id = "chatwoot:#{item['conversation_uuid']}:#{item['message_id']}"
      m.thread = item['thread_id'] if item['thread_id']
      m.type = item['type'] if item['type']
      m.to = item['to']
      message_add_body(m, item)

      document = m.document
      item['attachments']&.each { |url| m << oob(document, url) }
      m << Niceogiri::XML::Node.new(:request, document, 'urn:xmpp:receipts')
      m << Niceogiri::XML::Node.new(:markable, document, 'urn:xmpp:chat-markers:0')
    end
  end

  private

  def message_add_body(message, item)
    body = item['body'] && CommonMarker.render_doc(item['body'], :DEFAULT)
    message.body = body ? CommonMarker::Xep0393Renderer.new.render(body) : item['attachments']&.join(', ').to_s
    message.xhtml = body.to_html if body
  end

  def oob(document, attachment)
    Niceogiri::XML::Node.new(:x, document, 'jabber:x:oob').tap do |oob|
      oob << Niceogiri::XML::Node.new(:url, document, 'jabber:x:oob').tap do |url|
        url.content = attachment
      end
    end
  end

  def channel_class
    Channel::Xmpp
  end

  def perform_reply
    ::Redis::Alfred.lpush(
      'xmpp_outbound',
      {
        message_id: message.id,
        channel_id: channel.id,
        conversation_uuid: conversation.uuid,
        thread_id: conversation.additional_attributes['thread_id'],
        type: conversation.additional_attributes['type'],
        to: contact_inbox.source_id,
        body: message.content,
        attachments: message.attachments.map(&:file_url)
      }.to_json
    )
  end
end
