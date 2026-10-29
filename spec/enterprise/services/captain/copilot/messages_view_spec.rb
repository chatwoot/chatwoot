require 'rails_helper'

RSpec.describe Captain::Copilot::MessagesView do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: admin) }
  let(:collection) do
    CopilotRun::Collection.create!(account: account, user: admin, copilot_thread: thread, status: :completed,
                                   context: { resource: 'conversations', selected_ids: [conversation.id], as_of: 1.minute.from_now.iso8601 })
  end

  before do
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'How do I export contacts?')
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing, content: 'Agent reply text')
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Still waiting')
  end

  it "shows each conversation's first and latest customer messages, not agent replies" do
    content = described_class.new(collection).page(1)[:content]

    expect(content).to include("##{conversation.display_id}", 'How do I export contacts?', 'Still waiting')
    expect(content).not_to include('Agent reply text')
  end

  it 'refuses a collection of another resource' do
    collection.update!(context: collection.context.merge('resource' => 'contacts'))

    expect { described_class.new(collection).page(1) }.to raise_error(ArgumentError, /conversations collection/)
  end
end
