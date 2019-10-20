class Api::V1::Conversations::MessagesController < Api::BaseController
  before_action :set_conversation, only: [:create]

  def create
    mb = Messages::Outgoing::NormalBuilder.new(current_user, @conversation, params)
    @message = mb.perform
  end
end
