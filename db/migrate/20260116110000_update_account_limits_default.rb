class UpdateAccountLimitsDefault < ActiveRecord::Migration[7.0]
  def up
    # Update default for new accounts
    change_column_default :accounts, :limits, from: {}, to: { agents: 50, inboxes: 50 }

    # Update existing accounts
    Account.find_each do |account|
      limits = account.limits || {}

      limits['agents'] = 50
      limits['inboxes'] = 50
      account.update_columns(limits: limits)
    end
  end

  def down
    change_column_default :accounts, :limits, from: { agents: 50, inboxes: 50 }, to: {}
  end
end
