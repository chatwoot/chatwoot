# Lets the Pathors backend resolve an incoming call's dialled number back to the
# inbox that owns it, and to the bot that should answer for it.
class Api::V1::Accounts::Pathors::VoiceInboxesController < Api::V1::Accounts::BaseController
  def index
    @inboxes = Current.account.inboxes
                      .where(channel_type: 'Channel::Voice', channel_id: voice_channels.select(:id))
                      .includes(:channel, :agent_bot_inbox)
                      .order_by_name
  end

  private

  def voice_channels
    channels = Current.account.voice_channels
    return channels if params[:number].blank?

    channels.where(phone_number: params[:number])
  end
end
