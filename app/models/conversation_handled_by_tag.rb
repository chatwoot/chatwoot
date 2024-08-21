# == Schema Information
#
# Table name: conversation_handled_by_tags
#
#  id              :bigint           not null, primary key
#  handled_by      :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  conversation_id :bigint           not null
#  user_id         :bigint
#
# Indexes
#
#  index_conversation_handled_by_tags_on_conversation_id  (conversation_id)
#  index_conversation_handled_by_tags_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (user_id => users.id)
#
class ConversationHandledByTag < ApplicationRecord
  belongs_to :conversation
  belongs_to :user, optional: true

  validates :conversation_id, presence: true
  validates :handled_by, presence: true

  def current_user
    handled_by == 'human_agent' ? user : nil
  end
end
