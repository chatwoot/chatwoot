class RoomChannel < ApplicationCable::Channel
  def subscribed
    ensure_stream
    current_user
    current_account
    update_subscription
  end

  def update_presence
    update_subscription
    data = { account_id: @current_account.id, users: ::OnlineStatusTracker.get_available_users(@current_account.id) }
    data[:contacts] = ::OnlineStatusTracker.get_available_contacts(@current_account.id) if @current_user.is_a? User
    ActionCable.server.broadcast(@pubsub_token, { event: 'presence.update', data: data })
  end

  private

  def ensure_stream
    @pubsub_token = params[:pubsub_token]
    stream_from @pubsub_token
  end

  def update_subscription
    ::OnlineStatusTracker.update_presence(@current_account.id, @current_user.class.name, @current_user.id)
  end

  def current_user
    @current_user ||= if params[:user_id].blank?
                        Contact.find_by!(pubsub_token: @pubsub_token)
                      else
                        User.find_by!(pubsub_token: @pubsub_token, id: params[:user_id])
                      end
  end

  def current_account
    @current_account ||= if @current_user.is_a? Contact
                           @current_user.account
                         else
                           @current_user.accounts.find(params[:account_id])
                         end
  end
end
