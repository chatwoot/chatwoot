class Copilot::V2::ResponseJob < ApplicationJob
  queue_as :default

  def perform(account_id:, user_id:, copilot_thread_id:)
    account = Account.find(account_id)
    user = account.users.find(user_id)
    thread = account.copilot_threads.where(engine: :v2).find_by!(id: copilot_thread_id, user: user)

    return unless account.feature_enabled?('copilot_v2')

    Copilot::V2::ChatService.new(account: account, user: user, thread: thread, assistant: thread.assistant).generate_response
  end
end
