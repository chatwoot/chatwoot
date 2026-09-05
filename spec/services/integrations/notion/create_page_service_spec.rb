require 'rails_helper'

RSpec.describe Integrations::Notion::CreatePageService do
  subject(:service) { described_class.new(hook: hook, conversation: conversation) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :notion, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:notion_client) { instance_double(Notion) }

  before do
    allow(Notion).to receive(:new).with(hook.access_token.and_return(notion_client)
    allow(notion_client).to receive(:create_page)
  end

  describe '#perform' do
    context 'when the parent page is not configured' do
      it 'does not create a Notion page' do
        hook = create(:integrations_hook, :notion, account: account, settings: {})
        expect(Notion).not_to receive(:new)
        described_class.new(hook: hook, conversation: conversation).perform
      end
    end

    context 'when the parent page is configured' do
      it 'creates a page with the conversation summary' do
        create(:message, account: account, conversation: conversation, content: 'hello', message_type: :incoming)

        service.perform
        expect(notion_client).to have_received(:create_page).with(
          'notion_parent_page_id',
          a_string_including(conversation.display_id.to_s),
          array_including(hash_including(type: 'paragraph'))))
        )
      end
    end

    context 'when Notion API fails' do
      it 'tracks the exception instead of breaking the conversation flow' do
        allow(notion_client).to receive(:create_page).and_raise(StandardError, 'API down')
        exception_tracker = instance_double(ChatwootExceptionTracker)
        allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
        allow(exception_tracker).to receive(:capture_exception)

        expect { service.perform }.not_to raise_error
        expect(ChatwootExceptionTracker).to have_received(:new)
      end
    end
  end
end
