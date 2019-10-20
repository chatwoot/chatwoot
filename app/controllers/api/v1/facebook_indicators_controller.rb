class Api::V1::FacebookIndicatorsController < Api::BaseController
  before_action :set_access_token
  around_action :handle_with_exception

  def mark_seen
    Facebook::Messenger::Bot.deliver(payload('mark_seen'), access_token: @access_token)
    head :ok
  end

  def typing_on
    Facebook::Messenger::Bot.deliver(payload('typing_on'), access_token: @access_token)
    head :ok
  end

  def typing_off
    Facebook::Messenger::Bot.deliver(payload('typing_off'), access_token: @access_token)
    head :ok
  end

  private

  def handle_with_exception
    yield
  rescue Facebook::Messenger::Error => e
    true
  end

  def payload(action)
    {
      recipient: { id: params[:sender_id] },
      sender_action: action
    }
  end

  def set_access_token
    # have to cache this
    inbox = current_account.inboxes.find(params[:inbox_id])
    @access_token = inbox.channel.page_access_token
  end
end
