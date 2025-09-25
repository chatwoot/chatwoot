class Voice::BaseCallBuilder
  attr_reader :account, :inbox, :call_sid, :direction, :from_number, :to_number, :user, :contact, :conversation

  def initialize(account:, inbox:, call_sid:, direction:, from_number:, to_number:, user: nil, contact: nil)
    @account = account
    @inbox = inbox
    @call_sid = call_sid
    @direction = direction
    @from_number = from_number
    @to_number = to_number
    @user = user
    @contact = contact
    @conversation = nil
  end

  def perform
    ActiveRecord::Base.transaction do
      @conversation = find_existing_conversation || create_conversation!
      assign_identifier!
      ensure_conference_sid!
      refresh_call_metadata!
      create_or_update_call_message!
    end
    log_success!
    conversation
  end

  private

  def find_existing_conversation
    nil
  end

  def assign_identifier!
    return if call_sid.blank? || conversation.identifier == call_sid

    conversation.update!(identifier: call_sid)
  end

  def ensure_conference_sid!
    attrs = conversation.additional_attributes || {}
    return if attrs['conference_sid'].present?

    attrs['conference_sid'] = conference_sid_for(conversation)
    conversation.update!(additional_attributes: attrs)
  end

  def conference_sid_for(conversation)
    "conf_account_#{conversation.account_id}_conv_#{conversation.display_id}"
  end

  def refresh_call_metadata!
    attrs = (conversation.additional_attributes || {}).dup
    attrs['call_direction'] = direction
    attrs['call_type'] = direction
    attrs['call_status'] ||= 'ringing'
    attrs['meta'] ||= {}
    attrs['meta']['initiated_at'] ||= Time.current.to_i
    attrs.merge!(conversation_metadata_overrides)
    conversation.update!(
      additional_attributes: attrs,
      last_activity_at: Time.current
    )
    @contact ||= conversation.contact
  end

  def conversation_metadata_overrides
    {}
  end

  def create_or_update_call_message!
    Voice::CallMessageBuilder.new(
      conversation: conversation,
      direction: direction,
      call_sid: call_sid,
      conference_sid: conversation.additional_attributes['conference_sid'],
      from_number: from_number_for_message,
      to_number: to_number_for_message,
      user: message_sender
    ).perform
  end

  def from_number_for_message
    from_number || inbox.channel&.phone_number
  end

  def to_number_for_message
    to_number || contact&.phone_number
  end

  def message_sender
    nil
  end

  def log_success!
    Rails.logger.info(
      "VOICE_CALL_BUILDER account=#{account.id} inbox=#{inbox.id} conv=#{conversation.display_id} direction=#{direction} call_sid=#{call_sid}"
    )
  end

  def create_conversation!
    raise NotImplementedError
  end
end
