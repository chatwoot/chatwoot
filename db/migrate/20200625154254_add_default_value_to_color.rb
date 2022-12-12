class AddDefaultValueToColor < ActiveRecord::Migration[6.0]
  def up
    Label.where(color: nil).find_each { |u| u.update(color: '#fc7658') }

    change_column :labels, :color, :string, default: '#fc7658', null: false
  end

  def down
    change_column :labels, :color, :string, default: nil, null: true
  end
end
