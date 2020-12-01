class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  def index
    @messages = message_finder.perform
  end

  def create
    user = current_user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform
    if params[:MediaUrl0]
      file_resource = LocalResource.new(params[:MediaUrl0], params[:MediaContentType0])
      attachment = @message.attachments.new(
        account_id: @message.account_id,
        file_type: file_type(params[:MediaContentType0])
      )

      attachment.file.attach(
        io: file_resource.file,
        filename: file_resource.tmp_filename,
        content_type: file_resource.encoding
      )
      @message.save!
    end
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  private

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end
end
