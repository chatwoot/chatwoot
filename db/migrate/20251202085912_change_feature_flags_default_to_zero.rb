class ChangeFeatureFlagsDefaultToZero < ActiveRecord::Migration[7.0]
  def up
    # Change the default value from 7 to 0 (all feature flags disabled by default)
    change_column_default :channel_web_widgets, :feature_flags, from: 7, to: 0

    # Optional: Update existing records to 0 if you want to disable features for existing widgets
    # Uncomment the line below if you want to reset all existing widgets to have no features enabled
    # rubocop:disable Rails/SkipsModelValidations
    Channel::WebWidget.update_all(feature_flags: 0)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    # Revert back to default of 7 if needed
    change_column_default :channel_web_widgets, :feature_flags, from: 0, to: 7
  end
end
