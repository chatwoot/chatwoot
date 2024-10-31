class AddColumnsToStringeePhoneCall < ActiveRecord::Migration[7.0]
  def change
    remove_column :channel_stringee, :number_id, :integer
    add_column :channel_stringee, :group_id, :text, null: true
    add_column :channel_stringee, :route_type, :integer, null: false, default: 0
  end
end
