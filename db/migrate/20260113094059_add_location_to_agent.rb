# frozen_string_literal: true

class AddLocationToAgent < ActiveRecord::Migration[7.1] # :nodoc:
  def change
    add_reference :account_users, :location, foreign_key: true, index: true
  end
end
