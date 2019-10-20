class AddDisplayId < ActiveRecord::Migration[5.0]
  def change
    Conversation.all.each do |conversation|
      conversation.display_id = Conversation.where(account_id: conversation.account_id).maximum('display_id').to_i + 1
      conversation.save!
    end
  end
end
