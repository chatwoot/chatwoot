class BackfillCaptainCustomToolAssistants < ActiveRecord::Migration[7.2]
  def up
    assistant_model = Class.new(ActiveRecord::Base) { self.table_name = 'captain_assistants' }
    custom_tool_model = Class.new(ActiveRecord::Base) { self.table_name = 'captain_custom_tools' }

    custom_tool_model.where(assistant_id: nil).find_each do |tool|
      assistant_ids = assistant_model.where(account_id: tool.account_id).order(:id).pluck(:id)
      primary_assistant_id = assistant_ids.shift
      next unless primary_assistant_id

      assistant_ids.each do |assistant_id|
        custom_tool_model.create!(tool.attributes.except('id', 'assistant_id').merge('assistant_id' => assistant_id))
      end

      tool.update!(assistant_id: primary_assistant_id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Assistant tools may have been edited independently after the backfill'
  end
end
