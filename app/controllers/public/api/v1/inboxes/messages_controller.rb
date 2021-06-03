class Public::Api::V1::Inboxes::MessagesController < Public::Api::V1::InboxesController
  before_action :set_message, only: [:update]

  def index
    @messages = @conversation.nil? ? [] : message_finder.perform
  end

  def create
    @message = @conversation.messages.new(message_params)
    @message.save
    build_attachment
  end

  def update
    @message.update!(message_update_params)
  rescue StandardError => e
    render json: { error: @contact.errors, message: e.message }.to_json, status: 500
  end

  private

  def build_attachment
    return if params[:attachments].blank?

    params[:attachments].each do |uploaded_attachment|
      attachment = @message.attachments.new(
        account_id: @message.account_id,
        file_type: helpers.file_type(uploaded_attachment&.content_type)
      )
      attachment.file.attach(uploaded_attachment)
    end
    @message.save!
  end

  def message_finder_params
    {
      filter_internal_messages: true,
      before: params[:before]
    }
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, message_finder_params)
  end

  def message_update_params
    params.permit(submitted_values: [:name, :title, :value])
  end

  def permitted_params
    params.permit(:content, :echo_id)
  end

  def set_message
    @message = @conversation.messages.find(params[:id])
  end

  def message_params
    {
      account_id: @conversation.account_id,
      sender: @contact_inbox.contact,
      content: permitted_params[:content],
      inbox_id: @conversation.inbox_id,
      echo_id: permitted_params[:echo_id],
      message_type: :incoming
    }
  end
end
