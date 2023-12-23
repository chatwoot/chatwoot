class Enterprise::SlaJob < ApplicationJob
  queue_as :critical

  def perform(account)
    Enterprise::Sla::SlaService.new(account: account).perform
  end
end
