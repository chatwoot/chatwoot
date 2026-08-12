# frozen_string_literal: true

class AddActiveToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :active, :boolean, default: true, null: false
  end
end
