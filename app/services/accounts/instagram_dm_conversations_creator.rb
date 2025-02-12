class Accounts::InstagramDmConversationsCreator
  def initialize(account, user, params)
    @account = account
    @user = user
    @params = params
  end

  def build_contact_inbox(new_contact, inbox, source_id)
    existing_contact_inbox = ContactInbox.find_by(inbox_id: inbox.id, source_id: source_id)
    return existing_contact_inbox if existing_contact_inbox.present?

    ContactInbox.create!(
      contact: new_contact,
      inbox: inbox,
      source_id: source_id
    )
  end

  def perform
    @inbox = Inbox.find_by(id: @params[:inbox_id])
    return unless valid_instagram_inbox?

    # check if the dm conversation already created with comment_id then delete it
    return { error: 'DM conversation has already been created for this comment' } if if_dm_conversation_already_exist

    setup_contact_and_conversation
    send_instagram_message
    update_old_conversation
    add_private_note_on_new_conversation
    update_existing_message_status

    { success: true }
  rescue StandardError => e
    log_error(e)
    { error: 'An error occurred while processing the request' }
  end

  private

  def valid_instagram_inbox?
    @inbox&.channel_type == 'Channel::FacebookPage'
  end

  def setup_contact_and_conversation
    @contact = find_or_update_contact(@params[:contact_id], @account)
    @contact.save!
    @contact_inbox = build_contact_inbox(@contact, @inbox, @contact.identifier)
    @conversation = create_or_find_conversation
  end

  def create_or_find_conversation
    if @contact_inbox.contact_id == @contact.id
      find_or_create_conversation(@contact, @user, @account, @contact_inbox)
    else
      @existing_contact = Contact.find_by(id: @contact_inbox.contact_id)
      find_or_create_conversation(@existing_contact, @user, @account, @contact_inbox)
    end
  end

  def send_instagram_message
    Messages::MessageBuilder.new(@user, @conversation, message_params.to_h).perform
  end

  # rubocop:disable Layout/LineLength
  def add_private_note_on_new_conversation
    comment_conversation_link = "https://chat.bitespeed.co/app/accounts/#{@conversation.account_id}/conversations/#{@params[:conversation_id]}"
    private_message_params = private_message_params(@conversation,
                                                    "Conversation Moved from Instagram Comments.\n\nComment Conversation: #{comment_conversation_link}")
    @conversation.messages.create!(private_message_params)
  end
  # rubocop:enable Layout/LineLength

  def update_old_conversation
    old_conversation = Conversation.find_by(display_id: @params[:conversation_id], account_id: @account.id)
    new_conversation_link = "https://chat.bitespeed.co/app/accounts/#{@conversation.account_id}/conversations/#{@conversation.display_id}"
    private_message_params = private_message_params(old_conversation,
                                                    "Conversation Moved to Instagram DM.\n\nNew Conversation: #{new_conversation_link}")
    old_conversation.messages.create!(private_message_params)
  end

  def log_error(error)
    Rails.logger.error("Error in instagram_dm_conversations_creator: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
  end

  def find_or_update_contact(contact_id, _account)
    existing_contact = Contact.find_by(id: contact_id)

    # Update the additional_attributes with Instagram profile info
    current_attributes = existing_contact.additional_attributes || {}
    instagram_username = existing_contact.name

    current_attributes['social_profiles'] ||= {}
    current_attributes['social_profiles']['instagram'] = instagram_username
    current_attributes['social_instagram_user_name'] = instagram_username

    existing_contact.update!(
      additional_attributes: current_attributes
    )

    existing_contact
  end

  def private_message_params(conversation, content)
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :outgoing, private: true, content: content }
  end

  def activity_message_params(conversation, content)
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity, content: content }
  end

  def find_or_create_conversation(contact, _user, _account, contact_inbox)
    # Find latest conversation for this contact with the specific contact_inbox
    latest_conversation = contact.conversations
                                 .where(contact_inbox_id: contact_inbox.id)
                                 .order(created_at: :desc)
                                 .first

    if latest_conversation.blank?
      # Convert the params hash to ActionController::Parameters
      conversation_params = ActionController::Parameters.new(
        additional_attributes: {
          type: 'instagram_direct_message'
        }
      ).permit!

      conversation = ConversationBuilder.new(
        params: conversation_params,
        contact_inbox: contact_inbox
      ).perform
      return conversation
    elsif latest_conversation.status != 'open'
      latest_conversation.update!(status: 'open')
    end
    latest_conversation
  end

  def message_params
    message_params = @params.require(:message).permit(
      :content, :cc_emails, :bcc_emails, :attachments, :url_attachments,
      template_params: [:name, :category, :language, :namespace, { processed_params: [header: {}, body: {}, footer: {}] }],
      additional_attributes: {}, custom_attributes: {},
      content_attributes: {}
    )

    process_attachments(message_params)
    message_params[:content_attributes] = { reply_to_comment_id: @params[:comment_id] }
    message_params
  end

  def update_existing_message_status
    message_id = @params[:message_id]
    @message = Message.find_by(id: message_id)

    if @message
      updated_attributes = @message.content_attributes || {}
      updated_attributes[:is_dm_conversation_created] = true
      @message.update!(content_attributes: updated_attributes)
    else
      Rails.logger.error "Message not found for ID: #{message_id}"
    end
  end

  def if_dm_conversation_already_exist
    message_id = @params[:message_id]
    @message = Message.find_by(id: message_id)
    if @message
      @message.content_attributes[:is_dm_conversation_created]
    else
      Rails.logger.error "Message not found for ID: #{message_id}"
    end
  end

  def process_attachments(message_params)
    return if @params[:message][:attachments].blank?

    blobs = @params[:message][:attachments].map do |file|
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file.open,
        filename: file.original_filename,
        content_type: file.content_type
      )
      blob.signed_id
    end
    message_params['attachments'] = blobs
  end
end
