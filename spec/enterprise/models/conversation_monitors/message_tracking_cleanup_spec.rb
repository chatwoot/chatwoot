require 'rails_helper'

RSpec.describe ConversationMonitors::MessageTracking do
  it 'destroys a public message after its account has been removed' do
    conversation = create(:conversation)
    message = create(:message, account: conversation.account, conversation: conversation, inbox: conversation.inbox)
    conversation.account.delete

    expect { message.reload.destroy! }.not_to raise_error
    expect(Message.exists?(message.id)).to be(false)
  end
end
