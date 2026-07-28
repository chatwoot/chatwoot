class Api::V1::Accounts::Contacts::AttachmentsController < Api::V1::Accounts::Contacts::BaseController
  RESULTS_PER_PAGE = 100

  def index
    conversations = Conversations::PermissionFilterService.new(
      Current.account.conversations.where(contact_id: @contact.id),
      Current.user,
      Current.account
    ).perform

    @attachments = Attachment.where(message_id: Message.where(conversation_id: conversations).select(:id))
                             .includes({ file_attachment: :blob }, message: [:conversation, :inbox, { sender: { avatar_attachment: :blob } }])
                             .order(created_at: :desc)
                             .page(params[:page])
                             .per(RESULTS_PER_PAGE)
    @attachments_count = @attachments.total_count
  end
end
