class AddAccountIdToTickets < ActiveRecord::Migration[7.0]
  def change
    add_reference :tickets, :account, foreign_key: true
  end
end
