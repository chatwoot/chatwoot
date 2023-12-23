class AddDescriptionToSlaPolicy < ActiveRecord::Migration[7.0]
  def change
    add_column :sla_policies, :description, :string
  end
end
