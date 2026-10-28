class AddEpisodeGrainToConversationOutcomes < ActiveRecord::Migration[7.1]
  # The table has no writers yet (outcome tracking is unreleased), so no data
  # handling is needed: columns can be added NOT NULL and indexes swapped freely.
  def change
    change_table :conversation_outcomes, bulk: true do |t|
      t.string :episode_trigger, null: false, default: 'initial'
      t.datetime :started_at, null: false # rubocop:disable Rails/NotNullColumn -- table is empty, no default is meaningful
      t.datetime :ended_at

      t.remove :reopen_count, type: :integer, null: false, default: 0
      t.remove :last_reopened_at, type: :datetime
    end

    swap_episode_indexes
  end

  private

  def swap_episode_indexes
    remove_index :conversation_outcomes, name: 'idx_conversation_outcomes_unique_conversation',
                                         column: [:account_id, :assistant_id, :conversation_id], unique: true
    add_index :conversation_outcomes, [:account_id, :conversation_id, :started_at],
              unique: true, name: 'idx_conversation_outcomes_unique_boundary'
    add_index :conversation_outcomes, [:account_id, :conversation_id],
              unique: true, where: 'ended_at IS NULL',
              name: 'idx_conversation_outcomes_open_episode'
    add_index :conversation_outcomes, [:account_id, :conversation_id],
              unique: true, where: "episode_trigger = 'initial'",
              name: 'idx_conversation_outcomes_initial_episode'

    remove_index :conversation_outcomes, name: 'idx_conversation_outcomes_on_assistant_created_at',
                                         column: [:account_id, :assistant_id, :created_at]
    add_index :conversation_outcomes, [:account_id, :assistant_id, :started_at],
              name: 'idx_conversation_outcomes_on_assistant_started_at'
  end
end
