class Api::V1::Accounts::Conversations::TimelineController < Api::V1::Accounts::Conversations::BaseController
  def show
    @timeline = Conversations::TimelineBuilder.new(conversation: @conversation, user: Current.user).perform
  end
end
