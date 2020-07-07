class Api::V1::Accounts::FacebookIndicatorsController < Api::V1::Accounts::BaseController
  before_action :set_access_token
  around_action :handle_with_exception

  def mark_seen
    fb_bot.deliver(payload('mark_seen'), access_token: @access_token)
    head :ok
  end

  def typing_on
    fb_bot.deliver(payload('typing_on'), access_token: @access_token)
    head :ok
  end

  def typing_off
    fb_bot.deliver(payload('typing_off'), access_token: @access_token)
    head :ok
  end

  private

  def fb_bot
    ::Facebook::Messenger::Bot
  end

  def handle_with_exception
    yield
  rescue Facebook::Messenger::Error => e
    Rails.logger.debug "Rescued: #{e.inspect}"
    true
  end

  def payload(action)
    {
      recipient: { id: contact.source_id },
      sender_action: action
    }
  end

  def inbox
    @inbox ||= Current.account.inboxes.find(permitted_params[:inbox_id])
  end

  def set_access_token
    @access_token = inbox.channel.page_access_token
  end

  def contact
    @contact ||= inbox.contact_inboxes.find_by!(contact_id: permitted_params[:contact_id])
  end

  def permitted_params
    params.permit(:inbox_id, :contact_id)
  end
end
