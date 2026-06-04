module GroupConversationHandler # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  # This concern provides the base logic for handling group conversations across all channels.
  # Channel-specific handlers should include this concern and implement the required abstract methods.
  #
  # Abstract methods that must be implemented by including modules:
  # - extract_group_identifier: Returns a unique identifier for the group
  # - extract_group_source_id: Returns the source_id for the group contact_inbox
  # - extract_group_name: Returns the display name of the group
  # - extract_sender_identifier: Returns a unique identifier for the message sender
  # - extract_sender_source_id: Returns the source_id for the sender contact_inbox
  # - extract_sender_name: Returns the display name of the sender
  # - extract_sender_phone: Returns the phone number of the sender
  # - build_sender_contact_attributes: Returns a hash of attributes for the sender contact

  private

  def find_or_create_group_contact
    group_contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: extract_group_source_id,
      inbox: inbox,
      contact_attributes: {
        name: extract_group_name || extract_group_source_id,
        identifier: extract_group_identifier,
        group_type: :group
      }
    ).perform

    contact = group_contact_inbox.contact
    update_group_contact_info(contact)

    [group_contact_inbox, contact]
  end

  def update_group_contact_info(contact)
    update_params = {}
    group_name = extract_group_name
    update_params[:name] = group_name if group_name.present? && contact.name != group_name
    update_params[:group_type] = :group unless contact.group_type_group?
    contact.update!(update_params) if update_params.present?
  end

  def find_or_create_sender_contact
    source_id = extract_sender_source_id
    return nil if source_id.blank?

    sender_contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: inbox,
      contact_attributes: build_sender_contact_attributes
    ).perform

    sender_contact_inbox.contact
  end

  def find_or_create_group_conversation(group_contact_inbox)
    @conversation = group_contact_inbox.conversations.where(status: %i[open pending]).last
    if @conversation.present?
      @conversation.update!(group_type: :group) unless @conversation.group_type_group?
      return @conversation
    end

    @conversation = ::Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: group_contact_inbox.contact_id,
      contact_inbox_id: group_contact_inbox.id,
      group_type: :group
    )
  end

  def add_group_member(group_contact, contact, role: :member)
    return if group_contact.blank?
    return if contact.blank?

    member = GroupMember.find_or_initialize_by(
      group_contact: group_contact,
      contact: contact
    )

    member.update!(role: role, is_active: true) if member.new_record? || !member.is_active? || member.role != role.to_s
    member
  end

  def remove_group_member(group_contact, contact)
    return if group_contact.blank?
    return if contact.blank?

    member = GroupMember.find_by(group_contact: group_contact, contact: contact)
    member&.update!(is_active: false)
    member
  end

  def update_group_member_role(group_contact, contact, role)
    return if group_contact.blank?
    return if contact.blank?
    return if role.blank?

    member = GroupMember.find_by(group_contact: group_contact, contact: contact)
    member&.update!(role: role)
    member
  end

  def sync_group_members(group_contact, contacts, admins: [])
    contacts.each do |contact|
      role = admins.include?(contact) ? :admin : :member
      add_group_member(group_contact, contact, role: role)
    end

    current_member_ids = group_contact.group_memberships.active.pluck(:contact_id)
    new_contact_ids = contacts.map(&:id)
    removed_ids = current_member_ids - new_contact_ids

    group_contact.group_memberships.where(contact_id: removed_ids).find_each do |member|
      member.update!(is_active: false)
    end
  end

  def create_group_message(conversation:, sender_contact:, content:, message_type: :incoming, **options)
    return if conversation.blank?

    message_params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      message_type: message_type,
      content: content,
      sender: sender_contact
    }.merge(options)

    Message.create!(message_params)
  end

  def extract_group_identifier
    raise NotImplementedError, "#{self.class} must implement #extract_group_identifier"
  end

  def extract_group_source_id
    raise NotImplementedError, "#{self.class} must implement #extract_group_source_id"
  end

  def extract_group_name
    raise NotImplementedError, "#{self.class} must implement #extract_group_name"
  end

  def extract_sender_identifier
    raise NotImplementedError, "#{self.class} must implement #extract_sender_identifier"
  end

  def extract_sender_source_id
    raise NotImplementedError, "#{self.class} must implement #extract_sender_source_id"
  end

  def extract_sender_name
    raise NotImplementedError, "#{self.class} must implement #extract_sender_name"
  end

  def extract_sender_phone
    raise NotImplementedError, "#{self.class} must implement #extract_sender_phone"
  end

  def build_sender_contact_attributes
    phone = extract_sender_phone
    identifier = extract_sender_identifier

    attrs = { name: extract_sender_name }
    attrs[:phone_number] = phone if phone.present?
    attrs[:identifier] = identifier if identifier.present?
    attrs
  end
end
