class Api::V1::Widget::MessagesController < Api::V1::Widget::BaseController
  before_action :set_conversation, only: [:create]
  before_action :set_message, only: [:update]

  def index
    @messages = conversation.nil? ? [] : message_finder.perform
  end

  def create
    @message = conversation.messages.new(message_params)
    build_attachment
    @message.save!
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def update
    if @message.content_type == 'input_email'
      @message.update!(submitted_email: contact_email)
      ContactIdentifyAction.new(
        contact: @contact,
        params: { email: contact_email, name: contact_name },
        retain_original_contact_name: true
      ).perform
    elsif @message.content_type == 'input_phone'
      Rails.logger.info("Contact phone number: #{contact_phone_number}")
      Rails.logger.info("Contact name: #{contact_name}")
      Rails.logger.info("Contact email: #{contact_email}")
      @message.update!(submitted_phone: contact_phone_number)
      ContactIdentifyAction.new(
        contact: @contact,
        params: { phone_number: contact_phone_number, name: contact_name },
        retain_original_contact_name: true
      ).perform
    else
      @message.update!(message_update_params[:message])
    end
  rescue StandardError => e
    render json: { error: @contact.errors, message: e.message }.to_json, status: :internal_server_error
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

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

  def set_conversation
    @conversation = create_conversation if conversation.nil?
  end

  def message_finder_params
    {
      filter_internal_messages: true,
      before: permitted_params[:before],
      after: permitted_params[:after]
    }
  end

  def message_finder
    @message_finder ||= MessageFinder.new(conversation, message_finder_params)
  end

  def message_update_params
    # rubocop:disable Layout/LineLength
    params.permit(message: [
                    { submitted_values: [:name, :title, :value, { csat_survey_response: [:feedback_message, :rating] }, :user_phone_number, :user_order_id,
                                         :selected_reply] },
                    :user_phone_number,
                    :user_order_id,
                    :selected_reply
                  ])
    # rubocop:enable Layout/LineLength
  end

  # rubocop:disable Layout/LineLength
  def permitted_params
    # timestamp parameter is used in create conversation method

    params.permit(:id, :before, :after, :website_token, contact: [:name, :email],
                                                        message: [:content, :referer_url, :timestamp, :echo_id, :reply_to, :selected_reply, :phone_number, :order_id, :private])
  end

  # rubocop:enable Layout/LineLength
  def set_message
    @message = @web_widget.inbox.messages.find(permitted_params[:id])
  end
end
