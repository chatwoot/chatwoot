FactoryBot.define do
  factory :group_contact do
    conversation
    contact

    after(:build) do |group_contact|
      group_contact.account ||= group_contact.conversation&.account || group_contact.contact&.account || create(:account)
      group_contact.contact ||= create(:contact, account: group_contact.account)
      group_contact.conversation ||= create(:conversation, account: group_contact.account, group: true)
      group_contact.conversation.group = true
    end
  end
end
