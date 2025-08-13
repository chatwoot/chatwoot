class Api::V1::Accounts::Conversations::DirectUploadsController < ActiveStorage::DirectUploadsController
  include EnsureCurrentAccountHelper

  before_action :current_account
  before_action :conversation

  def create
    return if @conversation.nil? || @current_account.nil?

    super
  end

  private

  def conversation
    if instance_variable_defined?(:@conversation)
      @conversation
    else
      @conversation = Current.account.conversations.find_by(display_id: params[:conversation_id])
    end
  end
end
