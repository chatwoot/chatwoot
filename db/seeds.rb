account = Account.create!(name: 'Acme Inc')

devise_user = DeviseUser.new(
  name:"John",
  email: "john@acme.inc",
  password: "123456",
  user_attributes: {
    account_id: account.id,
    role: :administrator,
  },
)
devise_user.skip_confirmation!
devise_user.save!

web_widget = Channel::WebWidget.create!(
  account: account,
  website_name: 'Acme',
  website_url: 'https://acme.inc',
)

inbox = Inbox.create!(channel: web_widget, account: account, name: 'Acme Support')
InboxMember.create!(user: devise_user.user, inbox: inbox)

contact = Contact.create!(
  name: 'Jane',
  email: 'jane@example.com',
  phone_number: '0000',
  inbox: inboxes,
  account: account,
)
conversation = Conversation.create!(
  account: account,
  inbox: inbox,
  status: :open,
  assignee: devise_user.user,
  sender: contact,
)
Message.create!(
  content: "Hello",
  account: account,
  inbox: inbox,
  conversation: conversation,
  message_type: :incoming,
)
