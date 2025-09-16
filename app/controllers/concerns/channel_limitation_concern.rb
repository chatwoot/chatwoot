module ChannelLimitationConcern
  extend ActiveSupport::Concern

  included do
    before_action :check_max_channels, only: [:create]
  end

  private

  def check_max_channels
    max_channels = account.current_max_channels
    return if max_channels == 0  # 0 means unlimited
    
    render_error('Maximum number of channels reached') unless account.inboxes.count < max_channels
  end

  def account
    @account ||= Current.account
  end

  def render_error(message, status = :bad_request)
    render json: { error: message, message: message }, status: status
  end
end
