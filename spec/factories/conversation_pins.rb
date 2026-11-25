FactoryBot.define do
  factory :conversation_pin do
    conversation
    account { conversation.account }

    # A pin is only valid while the agent can still see the conversation, so the default puts the user in
    # the conversation's inbox rather than leaving a bare `create(:conversation_pin)` invalid. Callers that
    # bring their own user grant that access themselves.
    user do
      create(:user, account: conversation.account).tap do |agent|
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end
    end
  end
end
