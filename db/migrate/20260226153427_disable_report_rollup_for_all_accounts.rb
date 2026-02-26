class DisableReportRollupForAllAccounts < ActiveRecord::Migration[7.1]
  def up
    Account.find_each { |account| account.disable_features!(:report_rollup) }
  end
end
