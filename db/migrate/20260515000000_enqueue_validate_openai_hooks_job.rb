class EnqueueValidateOpenaiHooksJob < ActiveRecord::Migration[7.1]
  def up
    Migration::ValidateOpenaiHooksJob.perform_later
  end

  def down; end
end
