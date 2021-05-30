class AddDefaultValueToColor < ActiveRecord::Migration[6.0]
  def up
    Label.where(color: nil).find_each { |u| u.update(color: '#132a4f') }

    change_column :labels, :color, :string, default: '#132a4f', null: false
  end

  def down
    change_column :labels, :color, :string, default: nil, null: true
  end
end
