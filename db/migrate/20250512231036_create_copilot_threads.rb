class CreateCopilotThreads < ActiveRecord::Migration[7.0]
  def change
    create_table :copilot_threads do |t|
      t.string :title, null: false
      t.references :user, null: false, index: true
      t.references :account, null: false, index: true
      t.uuid :uuid, null: false, default: 'gen_random_uuid()'

      t.timestamps
    end

    add_index :copilot_threads, :uuid, unique: true
  end
end
