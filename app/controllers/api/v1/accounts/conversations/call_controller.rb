class Api::V1::Accounts::Conversations::CallController < Api::V1::Accounts::Conversations::BaseController
  include Events::Types

  def create
    broadcast(account, tokens, CALL_CREATED, call.push_event_data)
  end
end
