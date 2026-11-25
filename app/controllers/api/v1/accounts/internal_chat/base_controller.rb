class Api::V1::Accounts::InternalChat::BaseController < Api::V1::Accounts::BaseController
  before_action :ensure_internal_chat_access!

  private

  def ensure_internal_chat_access!
    raise Pundit::NotAuthorizedError unless FeatureAccess.new(Current.account).allows?(Current.account_user, 'internal_chat.access')
  end

  def current_channel
    @current_channel ||= Current.account.internal_chat_channels.find(params[:channel_id] || params[:id])
  end

  def current_membership
    @current_membership ||= current_channel.channel_members.find_by(user_id: Current.user.id)
  end

  def channel_member?
    current_channel.channel_type_public_channel? || current_membership.present?
  end

  def render_pro_required(feature)
    render json: { error: 'pro_feature_required', feature: feature }, status: :payment_required
  end
end
