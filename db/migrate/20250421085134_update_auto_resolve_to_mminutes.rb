class UpdateAutoResolveToMminutes < ActiveRecord::Migration[7.0]
  def change
    Account.where.not(auto_resolve_duration: nil).each do |account|
      account.auto_resolve_after = account.auto_resolve_duration * 60 * 24
      account.save!
    end
  end
end
