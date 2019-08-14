account = Account.create!([
  {name: "Google"}
])

User.create!([
  {email: "larry@google.com", encrypted_password: "$2a$11$CIyxMCfnm.FZ4arOR83AaORbgM7i2nrMPDKzxyfXd0fpkzumrWUlq", reset_password_token: nil, reset_password_sent_at: nil, remember_created_at: nil, sign_in_count: 0, current_sign_in_at: nil, last_sign_in_at: nil, current_sign_in_ip: nil, last_sign_in_ip: nil, account_id: account.id}
])


Channel.create!([
  {name: "Facebook Messenger"}
])
Contact.create!([
  {name: "izuck@facebook.com", email: nil, phone_number: "99496030692", channel_id: 1, account_id: 1}
])
Conversation.create!([
  {account_id: 1, channel_id: 1, inbox_id: 1, status: nil, assignee_id: 1, sender_id: 1}
])
Inbox.create!([
  {channel_id: 1, account_id: 1, name: "Google Car"},
  {channel_id: 1, account_id: 1, name: "Project Loon"}
])
InboxMember.create!([
  {user_id: 1, inbox_id: 1}
])
Message.create!([
  {content: "Hello", account_id: 1, channel_id: 1, inbox_id: 1, conversation_id: 1, type: nil}
])
