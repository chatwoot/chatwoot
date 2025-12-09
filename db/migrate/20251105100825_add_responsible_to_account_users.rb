# frozen_string_literal: true

class AddResponsibleToAccountUsers < ActiveRecord::Migration[7.1] # :nodoc:
  def change
    add_reference :account_users, :responsible, foreign_key: { to_table: :account_users }, index: true
  end
end
