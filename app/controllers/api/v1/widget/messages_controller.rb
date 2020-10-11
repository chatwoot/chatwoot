class Api::V1::Widget::MessagesController < Api::V1::Widget::BaseController
  before_action :set_message, only: [:update]

  def index
    @messages = message_finder.perform
  end

  def create
    build_message
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
    contact_with_email = @current_account.contacts.find_by(email: email)
    if contact_with_email
      @contact = ::ContactMergeAction.new(
        account: @current_account,
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

  def conversation
    @conversation ||= conversations.find_by!(display_id: permitted_params[:conversation_id])
  end

  def permitted_params
    params.permit(:id, :conversation_id, :before, :website_token, contact: [:email], message: [:content, :echo_id])
  end

  def set_message
    @message = @web_widget.inbox.messages.find(permitted_params[:id])
  end
end
