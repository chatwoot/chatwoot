class Account::UpdateAccountLimitsJob < ApplicationJob
  queue_as :default

  def perform
    # Fetch all accounts
    accounts = Account.all

    # Iterate through each account and update limits
    accounts.each do |account|
      # Ensure that the limits field exists and is a JSON object
      next unless account.limits.is_a?(Hash)

      # Remove "chat" and "history" keys from the limits field
      account.limits.delete("chat")
      account.limits.delete("history")

      # Save the updated limits back to the database
      account.save
    end
  end
end
