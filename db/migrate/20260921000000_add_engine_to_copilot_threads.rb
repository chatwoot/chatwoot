class AddEngineToCopilotThreads < ActiveRecord::Migration[7.1]
  def change
    add_column :copilot_threads, :engine, :string, default: 'legacy', null: false
    add_check_constraint :copilot_threads, "engine IN ('legacy', 'v2')", name: 'copilot_threads_engine_check'
  end
end
