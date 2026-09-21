class Copilot::V2::ResponseJob < ApplicationJob
  queue_as :default

  def perform(account_id:, user_id:, copilot_thread_id:, copilot_message_id:)
    account = Account.find(account_id)
    user = account.users.find(user_id)
    thread = account.copilot_threads.where(engine: :v2).find_by!(id: copilot_thread_id, user: user)
    message = thread.copilot_messages.find(copilot_message_id)
    Copilot::V2::RunService.new(thread: thread, user: user).start(message: message)
  end
end
