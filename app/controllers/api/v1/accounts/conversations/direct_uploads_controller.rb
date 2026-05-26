class Api::V1::Accounts::Conversations::DirectUploadsController < ActiveStorage::DirectUploadsController
  include EnsureCurrentAccountHelper
  include AccessTokenAuthHelper
  before_action :prevent_read_only_access_token!
  before_action :current_account
  before_action :conversation

  def create
    return if @conversation.nil? || @current_account.nil?

    super
  end

  private

  def conversation
    @conversation ||= Current.account.conversations.find_by(display_id: params[:conversation_id])
  end
end
