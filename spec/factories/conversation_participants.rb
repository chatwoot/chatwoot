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
