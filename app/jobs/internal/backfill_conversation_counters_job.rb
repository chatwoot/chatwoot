class Internal::BackfillConversationCountersJob < ApplicationJob
  queue_as :low

  def perform(account)
    Internal::BackfillConversationCountersService.new(account: account).perform
  end
end
