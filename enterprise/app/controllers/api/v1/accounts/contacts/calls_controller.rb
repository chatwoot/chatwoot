class Api::V1::Accounts::Contacts::CallsController < Api::V1::Accounts::BaseController
  before_action :contact
  before_action :voice_inbox

  def create
    authorize contact, :show?
    authorize voice_inbox, :show?

    result = Voice::OutboundCallBuilder.perform!(
      account: Current.account,
      inbox: voice_inbox,
      user: Current.user,
      contact: contact
    )

    conversation = result[:conversation]

    render json: {
      conversation_id: conversation.display_id,
      inbox_id: voice_inbox.id,
      call_sid: result[:call_sid],
      conference_sid: conversation.additional_attributes['conference_sid']
    }
  end

  private

  def contact
    @contact ||= Current.account.contacts.find(params[:id])
  end

  def voice_inbox
    @voice_inbox ||= Current.user.assigned_inboxes.where(
      account_id: Current.account.id,
      channel_type: 'Channel::Voice'
    ).find(params.require(:inbox_id))
  end
end
