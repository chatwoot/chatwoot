class RepurposeResponseBotFlagForCustomTools < ActiveRecord::Migration[7.1]
  def up
    # The response_bot flag (deprecated) has been renamed to custom_tools.
    # Disable it on any accounts that had response_bot enabled so the repurposed
    # flag starts in its intended default-off state.
    Account.feature_custom_tools.find_each(batch_size: 100) do |account|
      account.disable_features(:custom_tools)
      account.save!(validate: false)
    end
  end
end
