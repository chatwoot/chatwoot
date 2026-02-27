# == Schema Information
#
# Table name: conversation_participants
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_conversation_participants_on_account_id                   (account_id)
#  index_conversation_participants_on_conversation_id              (conversation_id)
#  index_conversation_participants_on_user_id                      (user_id)
#  index_conversation_participants_on_user_id_and_conversation_id  (user_id,conversation_id) UNIQUE
#
FactoryBot.define do
  factory :conversation_participant do
    conversation
    account

    before(:build) do |conversation|
      if conversation.user.blank?
        conversation.user = create(:user, account: conversation.account)
        create(:inbox_member, user: conversation.user, inbox: conversation.conversation.inbox)
      end
    end
  end
end
