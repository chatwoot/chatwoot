class AddStoresToCaptainCustomTools < ActiveRecord::Migration[7.2]
  def change
    add_column :captain_custom_tools, :stores, :jsonb, default: {}, null: false
  end
end
