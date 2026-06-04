class Api::V1::Accounts::Conversations::GroupsController < Api::V1::Accounts::BaseController
  before_action :set_inbox

  def create
    return render json: { error: 'Inbox must be an UnoAPI WhatsApp inbox' }, status: :unprocessable_entity unless unoapi_whatsapp_inbox?

    response = @inbox.channel.provider_service.create_group(
      subject: group_params[:subject],
      description: group_params[:description],
      participants: participant_payloads,
      join_approval_mode: group_params[:join_approval_mode]
    )
    return render json: { error: provider_error(response, 'Provider failed to create group') }, status: :unprocessable_entity unless response.success?

    @conversation = create_local_group_conversation(response.parsed_response.with_indifferent_access)
    render 'api/v1/accounts/conversations/create'
  end

  private

  def set_inbox
    @inbox = Current.account.inboxes.find(group_params[:inbox_id])
  end

  def unoapi_whatsapp_inbox?
    @inbox.channel_type == 'Channel::Whatsapp' && @inbox.channel.provider == 'unoapi'
  end

  def group_params
    params.permit(
      :inbox_id, :subject, :description, :join_approval_mode,
      participants: [:wa_id, :user_id, :phone_number, :phoneNumber, :pn, :jid, :lid]
    )
  end

  def participant_payloads
    @participant_payloads ||= Array(group_params[:participants]).filter_map do |participant|
      attrs = participant.to_h.with_indifferent_access
      wa_id = participant_phone_identifier(attrs)
      user_id = participant_lid_identifier(attrs)
      { wa_id: wa_id, user_id: user_id }.compact_blank.presence
    end
  end

  def participant_phone_identifier(attrs)
    [attrs[:wa_id], attrs[:phone_number], attrs[:phoneNumber], attrs[:pn], attrs[:jid], attrs[:id]].filter_map do |value|
      next if value.to_s.strip.end_with?('@lid')

      digits = value.to_s.gsub(/\D/, '')
      digits if digits.length >= 8
    end.first
  end

  def participant_lid_identifier(attrs)
    [attrs[:user_id], attrs[:lid], attrs[:wa_id], attrs[:jid], attrs[:id]].filter_map do |value|
      value = value.to_s.strip
      value if value.end_with?('@lid')
    end.first
  end

  def create_local_group_conversation(provider_group)
    group_id = provider_group[:id].presence || provider_group[:group_id].presence
    subject = provider_group[:subject].presence || group_params[:subject]
    group_picture = provider_group[:picture].presence || provider_group[:group_picture].presence
    contact_inbox = group_contact_inbox(group_id, subject, group_picture)

    conversation = @inbox.conversations.find_or_initialize_by(group: true, group_source_id: group_id)
    conversation.assign_attributes(local_group_conversation_attributes(conversation, provider_group, contact_inbox, subject, group_picture))
    conversation.save!
    conversation
  end

  def local_group_conversation_attributes(conversation, provider_group, contact_inbox, subject, group_picture)
    {
      account_id: Current.account.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      group_title: subject,
      group_description: provider_group[:description].presence || group_params[:description],
      group_invite_link: provider_group[:invite_link],
      group_join_approval_mode: provider_group[:join_approval_mode],
      additional_attributes: conversation.additional_attributes.to_h.merge(group_picture: group_picture).compact_blank,
      status: :open
    }
  end

  def group_contact_inbox(group_id, subject, group_picture)
    ContactInboxWithContactBuilder.new(
      source_id: group_id,
      inbox: @inbox,
      contact_attributes: { email: group_id, name: subject, avatar_url: group_picture }
    ).perform
  end

  def provider_error(response, fallback)
    response.parsed_response.try(:[], 'error') || fallback
  end
end
