class Zalo::IncomingMessageService
  include ::ZaloAttachmentHelper

  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    update_contact_from_profile if @contact.messages.empty?
    set_conversation
    @message = @conversation.messages.build(message_params)

    @message.content_attributes[:in_reply_to_external_id] = params[:message][:quote_msg_id] if params[:message][:quote_msg_id]

    attach_media
    @message.save!
  end

  private

  def account
    @account ||= @inbox.account
  end

  def channel
    @channel ||= @inbox.channel
  end

  def url_getprofile
    'https://openapi.zalo.me/v3.0/oa/user/detail'
  end

  def get_profile(user_id, access_token)
    HTTParty.get(
      url_getprofile,
      headers: { 'access_token' => access_token },
      query: { data: { user_id: user_id }.to_json }
    )
  end

  def update_contact_from_profile # rubocop:disable Metrics/AbcSize
    response = get_profile(params[:sender][:id], channel.oa_access_token)
    channel.refresh_access_token(channel) if response['error'] == -216

    # retry one time if error since it is rare but sometimes api got error
    response = get_profile(params[:sender][:id], channel.oa_access_token) unless response['error'].zero?

    return unless (response['error']).zero?

    @contact.update!(name: response['data']['display_name'])
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, response['data']['avatars']['240'])
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: params[:sender][:id],
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def message_params
    {
      content: params[:message][:text],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:message][:msg_id]
    }
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where
                                    .not(status: :resolved)
                                    .order(updated_at: :asc).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: params[:sender][:id]
    }
  end
end
