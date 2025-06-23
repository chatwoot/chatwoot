# frozen_string_literal: true

module Billing
  # Background job to create customers and subscriptions asynchronously
  # This improves user experience by not blocking the UI during API calls
  class CreateCustomerJob < ApplicationJob
    queue_as :default

    def perform(account, plan_name = nil)
      service = Billing::CreateCustomerService.new(account, plan_name)
      result = service.perform

      if result[:success]
        Rails.logger.info "Successfully created customer for account #{account.id}: #{result[:message]}"
      else
        Rails.logger.error "Failed to create customer for account #{account.id}: #{result[:error]}"
        # You might want to implement retry logic or notification here
      end

      result
    end
  end
end