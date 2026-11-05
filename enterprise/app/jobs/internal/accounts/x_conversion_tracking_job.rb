# frozen_string_literal: true

class Internal::Accounts::XConversionTrackingJob < ApplicationJob
  queue_as :purgable

  def perform(account_id, event_name)
    Internal::Accounts::XConversionTrackingService.new(account: Account.find(account_id), event_name: event_name).perform
  end
end
