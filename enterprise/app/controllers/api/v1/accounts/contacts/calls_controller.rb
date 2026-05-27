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
      contact: contact,
      conversation: existing_conversation
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

  # Reuse the open conversation when the caller is already inside it; ignore
  # the hint if it doesn't belong to the picked voice inbox or dialed contact.
  # Only reuse open conversations — Message#reopen_conversation skips outgoing
  # messages, so dropping a voice_call bubble into a resolved/snoozed/pending
  # thread leaves it stuck in that state.
  def existing_conversation
    return nil if params[:conversation_id].blank?

    conversation = Current.account.conversations.find_by(display_id: params[:conversation_id])
    return nil unless conversation
    return nil unless conversation.inbox_id == voice_inbox.id && conversation.contact_id == contact.id
    return nil unless conversation.open?

    conversation
  end
end
