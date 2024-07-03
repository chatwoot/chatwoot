class AddTeamIdToLabel < ActiveRecord::Migration[6.1]
  def change
    add_reference :labels, :team, foreign_key: true
  end
end
