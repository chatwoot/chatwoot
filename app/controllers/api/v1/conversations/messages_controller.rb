class Api::V1::Conversations::MessagesController < Api::BaseController
  before_action :set_conversation, only: [:index, :create]

  def index
    @messages = message_finder.perform
  end

  def create
    mb = Messages::Outgoing::NormalBuilder.new(current_user, @conversation, params)
    @message = mb.perform
  end

  private

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end
end
