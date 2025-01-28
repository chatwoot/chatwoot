class Accounts::OneClickConversationsCreator
  def initialize(account, user, params)
    @account = account
    @user = user
    @params = params
  end

  def perform
    Rails.logger.info("Processed message_params #{message_params.inspect}")
    contacts.each do |contact|
      CreateOneClickConversationJob.perform_later(
        contact.to_h,
        inbox_id,
        @account,
        @user,
        message_params,
        from_whatsapp?
      )
    end
    { success: true }
  rescue StandardError => e
    Rails.logger.error("Error in create_one_click_conversation: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    { error: 'An error occurred while processing the request' }
  end

  private

  def contacts
    contacts_array = JSON.parse(@params[:contacts])
    contacts_array.map do |contact|
      ActionController::Parameters.new(contact).permit(
        :name, :identifier, :email, :phone_number, :avatar, :blocked, :avatar_url,
        additional_attributes: {},
        custom_attributes: {}
      )
    end
  end

  def inbox_id
    @params[:inbox_id]
  end

  def from_whatsapp?
    @params[:isFromWhatsApp]
  end

  def message_params
    message_params = @params.require(:message).permit(
      :content, :cc_emails, :bcc_emails, :attachments, :url_attachments,
      template_params: [:name, :category, :language, :namespace, { processed_params: [header: {}, body: {}, footer: {}] }],
      additional_attributes: {}, custom_attributes: {}
    )

    process_template_params(message_params)
    process_attachments(message_params)
    message_params
  end

  def process_template_params(message_params)
    return unless @params.dig(:message, :template_params).is_a?(String)

    message_params[:template_params] = JSON.parse(@params.dig(:message, :template_params))
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
