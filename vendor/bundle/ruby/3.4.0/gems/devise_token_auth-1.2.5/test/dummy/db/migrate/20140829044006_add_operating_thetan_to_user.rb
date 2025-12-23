# frozen_string_literal: true

class AddOperatingThetanToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :operating_thetan, :integer
    add_column :users, :favorite_color, :string
  end
end
