class Whatsapp::MentionConverterService
  MENTION_REGEX = %r{\[@([^\]]+)\]\(mention://contact/(\d+)/([^)]+)\)}
  ALL_MENTION_REGEX = %r{\[@[^\]]*\]\(mention://contact/0/all\)}
  INCOMING_ALL_PATTERNS = /@(all|todos|everyone)\b/i

  class << self
    def extract_mentions_for_whatsapp(content, account)
      return {} if content.blank?

      mentions = collect_mention_jids(content, account)
      result = {}
      result[:mentions] = mentions if mentions.present?
      result[:groupMentions] = [{ groupSubject: 'everyone' }] if ALL_MENTION_REGEX.match?(content)
      result
    end

    # Replaces @DisplayName with @<jid_user> in outgoing rendered text so Baileys can match mentions
    def replace_mentions_in_outgoing_text(raw_content, rendered_text, account)
      return rendered_text if raw_content.blank? || rendered_text.blank?

      result = rendered_text.dup
      raw_content.scan(MENTION_REGEX).each do |display_name, id, _encoded_name|
        next if id == '0'

        jid_user = resolve_contact_jid_user(id, account)
        next if jid_user.blank? || jid_user == display_name

        result.sub!(/@#{Regexp.escape(display_name)}(?![\w(])/, "@#{jid_user}")
      end
      result
    end

    def convert_incoming_mentions(text, context_info, account, inbox)
      return text if text.blank? || context_info.blank?

      result = convert_jid_mentions(text.dup, context_info, account, inbox)
      convert_group_mentions(result, context_info)
    end

    private

    def collect_mention_jids(content, account)
      jids = content.scan(MENTION_REGEX).filter_map do |_name, id, _encoded_name|
        next if id == '0'

        contact = account.contacts.find_by(id: id)
        next if contact.blank?

        # Prefer LID identifier if available (e.g., "123456@lid")
        if contact.identifier.present? && contact.identifier.end_with?('@lid')
          contact.identifier
        elsif contact.phone_number.present?
          "#{contact.phone_number.delete('+')}@s.whatsapp.net"
        end
      end

      jids.compact.uniq
    end

    def resolve_contact_jid_user(contact_id, account)
      contact = account.contacts.find_by(id: contact_id)
      return nil if contact.blank?

      if contact.identifier.present? && contact.identifier.end_with?('@lid')
        contact.identifier.sub(/@lid$/, '')
      elsif contact.phone_number.present?
        contact.phone_number.delete('+')
      end
    end

    def convert_jid_mentions(text, context_info, account, inbox)
      mentioned_jids = context_info[:mentionedJid] || context_info['mentionedJid']
      return text if mentioned_jids.blank?

      mentioned_jids.reduce(text) do |result, jid|
        jid_user, jid_server = jid.split('@')

        if jid_server == 'lid'
          apply_lid_mention(result, jid_user, account, inbox)
        else
          apply_jid_mention(result, jid_user, account)
        end
      end
    end

    def apply_jid_mention(text, phone, account)
      contact = find_contact_by_phone(phone, account)
      return text unless contact

      display_name = contact.name.presence || phone
      encoded_name = ERB::Util.url_encode(display_name)
      mention_uri = "[@#{display_name}](mention://contact/#{contact.id}/#{encoded_name})"

      replace_mention_in_text(text, phone, display_name, mention_uri)
    end

    def apply_lid_mention(text, lid, account, inbox) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      contact = find_contact_by_lid(lid, account, inbox)
      return text unless contact

      contact_phone = contact.phone_number&.delete('+')
      display_name = contact.name.presence || contact_phone || lid
      encoded_name = ERB::Util.url_encode(display_name)
      mention_uri = "[@#{display_name}](mention://contact/#{contact.id}/#{encoded_name})"

      # Try @lid first, then @phone, then @displayName
      patterns = [/@#{Regexp.escape(lid)}/]
      patterns << /@#{Regexp.escape(contact_phone)}/ if contact_phone.present?
      patterns << /@#{Regexp.escape(display_name)}/i if display_name != lid && display_name != contact_phone

      patterns.each do |pattern|
        return text.sub(pattern, mention_uri) if text.match?(pattern)
      end

      text
    end

    def convert_group_mentions(text, context_info)
      group_mentions = context_info[:groupMentions] || context_info['groupMentions']
      return text if group_mentions.blank?

      text.gsub(INCOMING_ALL_PATTERNS, '[@all](mention://contact/0/all)')
    end

    def find_contact_by_phone(phone, account)
      # Try exact match first
      contact = account.contacts.find_by(phone_number: phone)
      contact ||= account.contacts.find_by(phone_number: "+#{phone}")

      # Brazilian number fallback: try last 8 digits
      if contact.nil? && phone.length >= 8
        last_digits = phone[-8..]
        contact = account.contacts.where('phone_number LIKE ?', "%#{last_digits}").first
      end

      contact
    end

    def find_contact_by_lid(lid, account, inbox)
      # Try by identifier (stored as "lid@lid")
      contact = account.contacts.find_by(identifier: "#{lid}@lid")
      return contact if contact

      # Fallback: try by contact_inbox source_id
      inbox.contact_inboxes.find_by(source_id: lid)&.contact
    end

    def replace_mention_in_text(text, phone, display_name, mention_uri)
      # Try @phone first, then @DisplayName
      patterns = [
        /@#{Regexp.escape(phone)}/,
        /@#{Regexp.escape(display_name)}/i
      ]

      patterns.each do |pattern|
        return text.sub(pattern, mention_uri) if text.match?(pattern)
      end

      text
    end
  end
end
