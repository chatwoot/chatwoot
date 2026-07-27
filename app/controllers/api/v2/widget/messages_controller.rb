class Api::V2::Widget::MessagesController < Api::V2::Widget::BaseController
  before_action :set_message, only: [:update]

  def index
    @conversation = conversation
    @messages = message_finder.perform
  end

  def create
    @message = conversation.messages.new(message_params_for(conversation))
    build_attachment
    @message.save!
    ensure_human_section_status(conversation)
  end

  def update
    if @message.content_type == 'input_email'
      @message.update!(submitted_email: contact_email)
      ContactIdentifyAction.new(
        contact: @contact,
        params: { email: contact_email, name: contact_name },
        retain_original_contact_name: true
      ).perform
    else
      @message.update!(message_update_params[:message])
    end
  rescue StandardError => e
    render json: { error: @contact.errors, message: e.message }.to_json, status: :internal_server_error
  end

  private

  def build_attachment
    return if params[:message][:attachments].blank?

    params[:message][:attachments].each do |uploaded_attachment|
      attachment = @message.attachments.new(
        account_id: @message.account_id,
        file: uploaded_attachment
      )

      attachment.file_type = helpers.file_type(uploaded_attachment&.content_type) if uploaded_attachment.is_a?(ActionDispatch::Http::UploadedFile)
    end
  end

  def message_finder
    MessageFinder.new(conversation, filter_internal_messages: true, before: permitted_params[:before], after: permitted_params[:after])
  end

  def set_message
    @message = conversation.messages.find(permitted_params[:id])
  end

  def message_update_params
    params.permit(message: [{ submitted_values: [:name, :title, :value, { csat_survey_response: [:feedback_message, :rating] }] }])
  end

  def permitted_params
    params.permit(
      :id, :before, :after, :website_token, :conversation_display_id,
      contact: [:name, :email],
      message: [:content, :referer_url, :timestamp, :echo_id, :reply_to]
    )
  end
end
