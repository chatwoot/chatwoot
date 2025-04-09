class ConvertAutoResolveDurationToMinutes < ActiveRecord::Migration[7.0]
  def up
    # Convert existing auto_resolve_duration values from days to minutes
    Account.where.not(auto_resolve_duration: nil).each do |account|
      # rubocop:disable Rails/SkipsModelValidations
      account.update_column(:auto_resolve_duration, account.auto_resolve_duration * 1440)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def down
    # Convert back from minutes to days (rounding to nearest day for safety)
    Account.where.not(auto_resolve_duration: nil).each do |account|
      days = (account.auto_resolve_duration / 1440.0).round
      # rubocop:disable Rails/SkipsModelValidations
      account.update_column(:auto_resolve_duration, days)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
