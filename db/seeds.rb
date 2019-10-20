account = Account.create!([
                            { name: 'Google' }
                          ])

user = User.new(name: 'lary', email: 'larry@google.com', password: '123456', account_id: account.first.id)
user.skip_confirmation!
user.save!

channels = Channel.create!([
                             { name: 'Facebook Messenger' }
                           ])

inboxes = Inbox.create!([
                          { channel: channels.first, account_id: 1, name: 'Google Car' },
                          { channel: channels.first, account_id: 1, name: 'Project Loon' }
                        ])

Contact.create!([
                  { name: 'izuck@facebook.com', email: nil, phone_number: '99496030692', inbox_id: inboxes.first.id, account_id: 1 }
                ])
Conversation.create!([
                       { account_id: 1, inbox_id: 1, status: :open, assignee_id: 1, sender_id: 1 }
                     ])

InboxMember.create!([
                      { user_id: 1, inbox_id: 1 }
                    ])
Message.create!([
                  { content: 'Hello', account_id: 1, inbox_id: 1, conversation_id: 1, message_type: :incoming }
                ])
