class CreateDefaultPriorityGroups < ActiveRecord::Migration[7.1]
  def up
    Account.find_each do |account|
      PriorityGroup.find_or_create_by!(name: "regular", account_id: account.id)
      PriorityGroup.find_or_create_by!(name: "vip", account_id: account.id)
    end
  end

  def down
    Account.find_each do |account|
      PriorityGroup.where(name: ["regular", "vip"], account_id: account.id).delete_all
    end
  end
end
