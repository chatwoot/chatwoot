class PurgePendingCaptainAssistantResponses < ActiveRecord::Migration[7.1]
  def up
    execute('DELETE FROM captain_assistant_responses WHERE status = 0')
  end

  def down; end
end
