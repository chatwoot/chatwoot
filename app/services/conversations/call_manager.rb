class Conversations::CallManager
  include Events::Types

  attr_reader :account, :user, :conversation, :params

  def initialize(account, user, conversation, params)
    @account = account
    @user = user
    @conversation = conversation
    @params = params
  end

  def create_call
    Rails.configuration.dispatcher.dispatch(CALL_CREATED, Time.zone.now, account: @account, user: @user, conversation: @conversation,
                                                                         room_id: @params[:room_id])
  end

  def end_call
    Rails.configuration.dispatcher.dispatch(CALL_ENDED, Time.zone.now, account: @account, user: @user, conversation: @conversation,
                                                                       room_id: @params[:room_id])
  end
end
