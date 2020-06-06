class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
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
