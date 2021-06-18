class Public::Api::V1::InboxesController < PublicController
  before_action :set_inbox_channel
  before_action :set_contact_inbox
  before_action :set_conversation

  private

  def set_inbox_channel
    @inbox_channel = ::Channel::Api.find_by!(identifier: params[:inbox_id])
  end

  def set_contact_inbox
    return if params[:contact_id].blank?

    @contact_inbox = @inbox_channel.inbox.contact_inboxes.find_by!(source_id: params[:contact_id])
  end

  def set_conversation
    return if params[:conversation_id].blank?

    @conversation = @contact_inbox.contact.conversations.find_by!(display_id: params[:conversation_id])
  end
end
