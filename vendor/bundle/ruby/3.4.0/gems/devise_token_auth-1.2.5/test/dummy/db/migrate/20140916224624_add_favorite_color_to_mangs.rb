# frozen_string_literal: true

class AddFavoriteColorToMangs < ActiveRecord::Migration[4.2]
  def change
    add_column :mangs, :favorite_color, :string
  end
end
