# frozen_string_literal: true

class AddBoardFlagToCustomFilter < ActiveRecord::Migration[7.1] # :nodoc:
  def change
    add_column :custom_filters, :is_board, :boolean, default: false, null: false
  end
end
