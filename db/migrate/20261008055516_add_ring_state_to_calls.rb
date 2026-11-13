class AddRingStateToCalls < ActiveRecord::Migration[7.2]
  def change
    # Who a ring went to and which devices were rung, kept out of `meta` so a write of
    # `meta` from a copy of the call loaded earlier cannot erase it
    add_column :calls, :ring_state, :jsonb, default: {}, null: false
  end
end
