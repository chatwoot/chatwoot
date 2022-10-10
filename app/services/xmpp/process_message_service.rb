class Xmpp::ProcessMessageService
  def initialize(channel, message, mam_id: nil, delay: nil)
    @channel = channel
    @message = message
    @mam_id = mam_id
    @delay = delay
  end

  def mam_id
    @mam_id ||= @message.xpath('./ns:stanza-id', ns: 'urn:xmpp:sid:0').find { |el| el['by'] == @channel.jid }&.[]('id')
  end

  def created_at
    (@delay ? Time.parse(@delay).utc : @message.delay&.stamp) || Time.now.utc
  end

  def contact_jid
    @message.from.stripped
  end

  def contact_inbox
    @channel.with_lock do
      @contact_inbox ||= ContactInboxWithContactBuilder.new(
        source_id: contact_jid.to_s,
        inbox: @channel.inbox,
        contact_attributes: {
          name: contact_jid.node.to_s,
          custom_attributes: {
            jid: contact_jid.to_s
          }
        }
      ).perform
    end
  end

  def contact
    @contact ||= contact_inbox.contact
  end

  def conversation
    additional_attributes = {
      source: 'xmpp',
      type: @message.type
    }

    @conversation ||=
      @channel.with_lock do
        if @message.thread
          additional_attributes[:thread_id] = @message.thread
          additional_attributes[:initiated_at] = { timestamp: Time.now.utc }
          contact_inbox.conversations.where("additional_attributes->>'thread_id' = ?", @message.thread).last || threaded_conversation_fallback
        else
          find_threadless_conversation
        end || create_conversation!(additional_attributes)
      end
  end

  def threaded_conversation_fallback; end

  def find_threadless_conversation
    contact_inbox.conversations.where("additional_attributes->>'thread_id' IS NULL AND additional_attributes->>'type'=?", @message.type).last
  end

  def create_conversation!(additional_attributes)
    @channel.inbox.conversations.create!(
      account: @channel.account,
      contact: contact, contact_inbox: contact_inbox,
      additional_attributes: additional_attributes
    )
  end

  def parse_message_id(stanza_id = @message.id)
    stanza_id&.scan(/\Achatwoot:([0-9a-f-]+):(\d+)\Z/)&.first
  end

  def already_sent_by_us?
    m_conversation_uuid, m_message_id = parse_message_id
    m_conversation_uuid == conversation.uuid && m_message_id && conversation.messages.find_by(id: m_message_id)
  end

  def already_have_mam_id?
    mam_id && conversation.messages.find_by(source_id: mam_id).present?
  end

  def sender
    conversation.contact
  end

  def message_type
    'incoming'
  end

  def oob
    @message.xpath('./ns:x/ns:url', ns: 'jabber:x:oob').map { |x| URI.parse(x.content) }
  end

  def content
    oob.reduce(@message.body.to_s) { |b, uri| b.sub(uri.to_s, '') }
  end

  def db_message
    @db_message ||= conversation.messages.create!(
      account_id: conversation.account_id,
      sender: sender, content: content,
      inbox_id: conversation.inbox_id,
      message_type: message_type,
      content_type: 'text',
      source_id: mam_id,
      created_at: created_at,
      content_attributes: {
        subject: @message.subject,
        stanza: @message.to_xml
      }
    )
  end

  def add_attachments
    oob.each do |uri|
      io = uri.open
      type = io.content_type.split('/').first.to_sym
      type = :file unless Attachment.file_types.key?(type)
      db_message.attachments.create!(
        account_id: conversation.account_id,
        file_type: type,
        file: {
          io: io,
          filename: File.basename(uri.path),
          content_type: io.content_type
        }
      )
    rescue OpenURI::HTTPError, OpenSSL::SSL::SSLError
      Blather.logger.error "Could not download attachment for #{uri} to #{db_message.id}"
    end
  end

  # rubocop:disable Rails/SkipsModelValidations
  # Avoid cross-thread contention on an object property we don't even read again by using update_all
  # There is no validation on this column, so it is safe
  def record_last_mam_id
    Channel::Xmpp.where(id: @channel.id).update_all(last_mam_id: mam_id) if mam_id
  end
  # rubocop:enable Rails/SkipsModelValidations

  def perform
    ActiveRecord::Base.transaction do
      next if already_sent_by_us?
      next if already_have_mam_id?

      db_message
      add_attachments
    end
  end

  class Outgoing < self
    def contact_jid
      @message.to.stripped
    end

    def sender
      AgentBot.find_by(name: 'XMPP') || AgentBot.create!(name: 'XMPP')
    end

    def message_type
      'outgoing'
    end

    def threaded_conversation_fallback
      find_threadless_conversation
    end

    # Find a previously sent message by stanza id
    def find_message(stanza_id)
      m_conversation_uuid, m_message_id = parse_message_id(stanza_id)

      m = Message.find_by(id: m_message_id)
      return unless m && m.conversation.uuid == m_conversation_uuid

      m
    end
  end
end
