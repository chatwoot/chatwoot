class Api::V1::Widget::MessagesController < Api::V1::Widget::BaseController
  before_action :set_conversation, only: [:create]
  before_action :set_message, only: [:update]

  def index
    @messages = conversation.nil? ? [] : message_finder.perform
  end

  def create
    @message = conversation.messages.new(message_params)
    @message.save
    build_attachment
  end

  def update
    if @message.content_type == 'input_email'
      @message.update!(submitted_email: contact_email)
      update_contact(contact_email)
    else
      @message.update!(message_update_params[:message])
    end
  rescue StandardError => e
    render json: { error: @contact.errors, message: e.message }.to_json, status: 500
  end

  private

  def build_attachment
    return if params[:message][:attachments].blank?

    params[:message][:attachments].each do |uploaded_attachment|
      attachment = @message.attachments.new(
        account_id: @message.account_id,
        file_type: helpers.file_type(uploaded_attachment&.content_type)
      )
      attachment.file.attach(uploaded_attachment)
    end
    @message.save!
  end

  def set_conversation
    @conversation = ::Conversation.create!(conversation_params) if conversation.nil?
  end

  def message_params
    {
      account_id: conversation.account_id,
      sender: @contact,
      content: permitted_params[:message][:content],
      inbox_id: conversation.inbox_id,
      echo_id: permitted_params[:message][:echo_id],
      message_type: :incoming
    }
  end

  def conversation_params
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        browser: browser_params,
        referer: permitted_params[:message][:referer_url],
        initiated_at: timestamp_params
      }
    }
  end

  def timestamp_params
    {
      timestamp: permitted_params[:message][:timestamp]
    }
  end

  def inbox
    @inbox ||= ::Inbox.find_by(id: auth_token_params[:inbox_id])
  end

  def message_finder_params
    {
      filter_internal_messages: true,
      before: permitted_params[:before]
    }
  end

  def message_finder
    @message_finder ||= MessageFinder.new(conversation, message_finder_params)
  end

  def update_contact(email)
    contact_with_email = @account.contacts.find_by(email: email)
    if contact_with_email
      @contact = ::ContactMergeAction.new(
        account: @account,
        base_contact: contact_with_email,
        mergee_contact: @contact
      ).perform
    else
      @contact.update!(
        email: email,
        name: contact_name
      )
    end
  end

  def contact_email
    permitted_params[:contact][:email].downcase
  end

  def contact_name
    contact_email.split('@')[0]
  end

  def message_update_params
    params.permit(message: [{ submitted_values: [:name, :title, :value] }])
  end

  def permitted_params
    params.permit(:id, :before, :website_token, contact: [:email], message: [:content, :referer_url, :timestamp, :echo_id])
  end

  def set_message
    @message = @web_widget.inbox.messages.find(permitted_params[:id])
  end
end
