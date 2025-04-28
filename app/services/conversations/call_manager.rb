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
    call = {
      room_id: @params[:room_id],
      domain: @params[:domain]
    }
    Rails.logger.info("Creating call: #{call}")
    Rails.configuration.dispatcher.dispatch(CALL_CREATED, Time.zone.now, account: @account, user: @user, conversation: @conversation,
                                                                         call: { call_data: call })
  end

  def end_call
    # NOTE: Unused as IFrame is not supported on customer side
    call = {
      room_id: @params[:room_id],
      domain: @params[:domain]
    }
    Rails.configuration.dispatcher.dispatch(CALL_ENDED, Time.zone.now, account: @account, user: @user, conversation: @conversation,
                                                                       call: { call_data: call })
  end
end
