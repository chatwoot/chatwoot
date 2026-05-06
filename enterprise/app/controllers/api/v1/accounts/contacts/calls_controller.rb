class Api::V1::Accounts::Contacts::CallsController < Api::V1::Accounts::BaseController
  before_action :contact
  before_action :voice_inbox

  def create
    authorize contact, :show?
    authorize voice_inbox, :show?

    call = Voice::OutboundCallBuilder.perform!(
      account: Current.account,
      inbox: voice_inbox,
      user: Current.user,
      contact: contact
    )

    render json: {
      conversation_id: call.conversation.display_id,
      inbox_id: voice_inbox.id,
      call_sid: call.provider_call_id,
      conference_sid: call.conference_sid
    }
  end

  private

  def contact
    @contact ||= Current.account.contacts.find(params[:id])
  end

  def voice_inbox
    @voice_inbox ||= begin
      inbox = Current.user.assigned_inboxes.where(
        account_id: Current.account.id,
        channel_type: 'Channel::TwilioSms'
      ).find(params.require(:inbox_id))
      raise ActiveRecord::RecordNotFound, 'Voice not enabled' unless inbox.channel.voice_enabled?

      inbox
    end
  end
end
