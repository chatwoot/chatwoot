class Voice::CallOrchestratorService
  attr_reader :account, :inbox, :direction, :phone_number, :contact, :user, :call_sid

  def initialize(account:, inbox:, direction:, phone_number: nil, contact: nil, user: nil, call_sid: nil)
    @account = account
    @inbox = inbox
    @direction = direction
    @phone_number = phone_number
    @contact = contact
    @user = user
    @call_sid = call_sid
  end

  def inbound!
    raise 'From number is required' if phone_number.blank?

    Voice::InboundCallBuilder.new(
      account: account,
      inbox: inbox,
      from_number: phone_number,
      call_sid: call_sid,
      to_number: inbox.channel&.phone_number
    ).perform
  end

  def outbound!
    raise 'Contact is required' if contact.blank?
    raise 'User is required' if user.blank?

    call_details = inbox.channel.initiate_call(
      to: contact.phone_number,
      conference_sid: nil,
      agent_id: user.id
    )

    conversation = Voice::OutboundCallBuilder.new(
      account: account,
      inbox: inbox,
      user: user,
      contact: contact,
      call_sid: call_details[:call_sid],
      to_number: contact.phone_number
    ).perform

    {
      conversation_id: conversation.display_id,
      call_sid: call_details[:call_sid],
      conference_sid: conversation.additional_attributes['conference_sid']
    }
  end
end
