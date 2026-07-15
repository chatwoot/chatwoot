class AddCompletedAtToAppliedSlas < ActiveRecord::Migration[7.1]
  def change
    add_column :applied_slas, :completed_at, :datetime
  end
end
