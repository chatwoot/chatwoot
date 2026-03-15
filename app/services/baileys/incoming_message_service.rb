module Baileys
  class IncomingMessageService
    pattr_initialize [:inbox!, :params!]

    def perform
      return unless processable_message?

      # Skip duplicates (history sync may re-deliver messages already received in real-time)
      return if params[:key]&.dig(:id).present? && Message.exists?(source_id: params[:key][:id].to_s)

      set_contact
      return unless @contact

      ActiveRecord::Base.transaction do
        set_conversation
        create_message
      end
    end

    private

    def processable_message?
      return false if newsletter_message?

      # Need either parsed content or raw message
      params[:content].present? || params[:message].present? || params[:media_path].present?
    end

    def set_contact
      if group_message?
        set_group_contact
      else
        set_individual_contact
      end
    end

    def set_individual_contact
      phone_number = individual_phone_number
      return if phone_number.blank?

      name = params.dig(:pushName) || "+#{phone_number}"
      waid = phone_number.gsub(/[^\d]/, '')

      contact_inbox = ::ContactInboxWithContactBuilder.new(
        source_id: "#{waid}@s.whatsapp.net",
        inbox: inbox,
        contact_attributes: { name: name, phone_number: "+#{waid}" }
      ).perform

      @contact_inbox = contact_inbox
      @contact = contact_inbox.contact

      update_contact_name(name) if @contact.name.start_with?('+')
    end

    def set_group_contact
      group_jid = params.dig(:key, :remoteJid)
      return if group_jid.blank?

      group_id = group_jid.split('@').first

      # The contact_inbox represents the group itself
      contact_inbox = ::ContactInboxWithContactBuilder.new(
        source_id: group_jid,
        inbox: inbox,
        contact_attributes: { name: "Group #{group_id}", phone_number: nil, identifier: group_jid }
      ).perform

      @contact_inbox = contact_inbox
      @contact = contact_inbox.contact
    end

    def set_conversation
      @conversation = if inbox.lock_to_single_conversation
                        @contact_inbox.conversations.last
                      else
                        @contact_inbox.conversations.where.not(status: :resolved).last
                      end
      return if @conversation

      @conversation = ::Conversation.create!(
        account_id: inbox.account_id,
        inbox_id: inbox.id,
        contact_id: @contact.id,
        contact_inbox_id: @contact_inbox.id
      )
    end

    def create_message
      @message = @conversation.messages.build(
        content: message_content,
        account_id: inbox.account_id,
        inbox_id: inbox.id,
        message_type: from_me? ? :outgoing : :incoming,
        sender: from_me? ? nil : @contact,
        source_id: params[:key]&.dig(:id).to_s
      )

      if history_message?
        @message.content_attributes = (@message.content_attributes || {}).merge('is_history' => true)
        ts = parse_timestamp(params[:messageTimestamp])
        @message.created_at = Time.zone.at(ts) if ts&.positive?
      end

      process_in_reply_to
      attach_media
      @message.save!
    end

    def message_content
      # Use pre-parsed content from sidecar (preferred)
      content = params[:content]
      return format_group_content(content) if content.present?

      # Fallback to raw message parsing (backwards compatibility)
      message_params = params[:message]
      return '' unless message_params

      message_params[:conversation] ||
        message_params[:extendedTextMessage]&.dig(:text) ||
        message_params[:imageMessage]&.dig(:caption) ||
        message_params[:videoMessage]&.dig(:caption) ||
        message_params[:documentMessage]&.dig(:caption) ||
        ''
    end

    def format_group_content(content)
      return content unless group_message?

      participant_name = params[:pushName] || params.dig(:key, :participant)&.split('@')&.first || 'Unknown'
      "**#{participant_name}:**\n#{content}"
    end

    def group_message?
      jid = params.dig(:key, :remoteJid)
      jid&.end_with?('@g.us')
    end

    def newsletter_message?
      jid = params.dig(:key, :remoteJid)
      jid&.end_with?('@newsletter')
    end

    def from_me?
      params[:key]&.dig(:fromMe) == true
    end

    def individual_phone_number
      key = params.dig(:key)
      return nil if key.blank?

      jid = key[:remoteJid]
      # Prefer phone-based JID; fall back to remoteJidAlt for LID addressing
      if jid&.end_with?('@lid') && key[:remoteJidAlt]&.end_with?('@s.whatsapp.net')
        jid = key[:remoteJidAlt]
      end
      return nil if jid.blank? || !jid.end_with?('@s.whatsapp.net')

      jid.split('@').first
    end

    def process_in_reply_to
      # Use pre-parsed quoted_message_id from sidecar (preferred)
      quoted_id = params[:quoted_message_id]
      # Fallback to raw message parsing
      quoted_id ||= params.dig(:message, :contextInfo, :stanzaId)
      return if quoted_id.blank?

      @message.content_attributes = (@message.content_attributes || {}).merge(in_reply_to_external_id: quoted_id)
    end

    def attach_media
      media_path = params[:media_path]
      return if media_path.blank?

      sidecar_url = ENV.fetch('BAILEYS_SIDECAR_URL', 'http://baileys:3500')
      media_url = "#{sidecar_url}#{media_path}"
      file = Down.download(media_url)
      return if file.blank?

      @message.attachments.new(
        account_id: @message.account_id,
        file_type: detect_file_type,
        file: {
          io: file,
          filename: params[:media_filename] || file.original_filename || "attachment_#{SecureRandom.hex(4)}",
          content_type: params[:media_mimetype] || file.content_type
        }
      )
    rescue Down::Error => e
      Rails.logger.error("[Baileys::IncomingMessageService] Media download failed: #{e.message}")
    end

    def detect_file_type
      case params[:message_type]
      when 'imageMessage' then :image
      when 'audioMessage' then :audio
      when 'videoMessage' then :video
      when 'documentMessage' then :file
      when 'stickerMessage' then :image
      else :file
      end
    end

    def update_contact_name(name)
      return if name.start_with?('+')

      @contact.update!(name: name)
    end

    def history_message?
      params[:is_history] == true
    end

    def parse_timestamp(value)
      case value
      when Integer, Float
        value.to_i
      when Hash
        # Protobuf Long: {low: N, high: N, unsigned: bool}
        value[:low].to_i
      when String
        value.to_i
      end
    end
  end
end
