class RepurposeResponseBotFlagForCaptainV1CustomTools < ActiveRecord::Migration[7.0]
  def up
    # The response_bot flag (deprecated) has been renamed to captain_v1_custom_tools.
    # Disable it on any accounts that had response_bot enabled so the repurposed
    # flag starts in its intended default-off state.
    Account.feature_captain_v1_custom_tools.find_each(batch_size: 100) do |account|
      account.disable_features(:captain_v1_custom_tools)
      account.save!(validate: false)
    end
  end
end
