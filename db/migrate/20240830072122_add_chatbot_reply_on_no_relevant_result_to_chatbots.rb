class AddChatbotReplyOnNoRelevantResultToChatbots < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :reply_on_no_relevant_result, :string
  end
end
