class RoomChannel < ApplicationCable::Channel
  def subscribed
    # TODO: should we only do ensure stream  if current account is present?
    # for now going ahead with guard clauses in update_subscription and broadcast_presence
    current_user
    current_account
    ensure_stream
    update_subscription
    broadcast_presence
  end

  def update_presence
    adopt_visitor_contact
    update_subscription
    broadcast_presence
  end

  private

  def broadcast_presence
    return if @current_account.blank?

    data = { account_id: @current_account.id, users: ::OnlineStatusTracker.get_available_users(@current_account.id) }
    data[:contacts] = ::OnlineStatusTracker.get_available_contacts(@current_account.id) if @current_user.is_a? User
    ActionCable.server.broadcast(pubsub_token, { event: 'presence.update', data: data })
  end

  def ensure_stream
    stream_from pubsub_token
    stream_from "account_#{@current_account.id}" if @current_account.present? && @current_user.is_a?(User)
  end

  def update_subscription
    # A visitor whose contact does not exist yet has nothing to track.
    return if @current_user.blank?

    ::OnlineStatusTracker.update_presence(@current_account.id, @current_user.class.name, @current_user.id)
  end

  def pubsub_token
    @pubsub_token ||= params[:pubsub_token]
  end

  def current_user
    @current_user ||= if params[:user_id].blank?
                        ContactInbox.find_by(pubsub_token: pubsub_token)&.contact
                      else
                        User.find_by!(pubsub_token: pubsub_token, id: params[:user_id])
                      end
  end

  def current_account
    @current_account ||= if @current_user.is_a?(User)
                           @current_user.accounts.find(params[:account_id])
                         elsif @current_user
                           @current_user.account
                         else
                           visitor_account
                         end
  end

  # Until the visitor's contact exists, the signed widget token is the only proof the stream is theirs;
  # it also names the inbox whose agent presence they should see.
  def visitor_account
    visitor_token = ::Widget::TokenService.new(token: params[:auth_token]).decode_token
    raise ActiveRecord::RecordNotFound if visitor_token[:pubsub_token].blank? || visitor_token[:pubsub_token] != pubsub_token

    ::Inbox.find(visitor_token[:inbox_id]).account
  end

  # The contact is created lazily (WebsiteTokenHelper#ensure_contact); pick it up on the next ping.
  def adopt_visitor_contact
    return if @current_user.present? || params[:user_id].present?

    @current_user = ContactInbox.find_by(pubsub_token: pubsub_token)&.contact
  end
end
