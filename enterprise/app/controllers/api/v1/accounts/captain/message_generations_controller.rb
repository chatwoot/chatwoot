class Api::V1::Accounts::Captain::MessageGenerationsController < Api::V1::Accounts::BaseController
  before_action :set_message
  before_action :authorize_conversation

  def show
    @message_generation = @message.captain_generation
    head :not_found if @message_generation.blank?
  end

  private

  def set_message
    @message = Current.account.messages.find(params[:id])
  end

  def authorize_conversation
    authorize @message.conversation, :show?
  end
end
