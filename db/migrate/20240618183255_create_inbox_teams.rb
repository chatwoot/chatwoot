class CreateInboxTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :inbox_teams do |t|
      t.integer 'team_id', null: false
      t.integer 'inbox_id', null: false
      t.index %w[inbox_id team_id], name: 'index_inbox_teams_on_inbox_id_and_team_id', unique: true
      t.index ['inbox_id'], name: 'index_inbox_teams_on_inbox_id'

      t.timestamps
    end
  end
end
