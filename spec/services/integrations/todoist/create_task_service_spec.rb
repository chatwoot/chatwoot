require 'rails_helper'

RSpec.describe Integrations::Todoist::CreateTaskService do
  subject(:service) { described_class.new(hook: hook, conversation: conversation) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :todoist, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:todoist_client) { instance_double(Todoist) }
  let(:response) { instance_double(HTTParty::Response, success?: true) }

  before do
    allow(Todoist).to receive(:new).with(hook.settings['api_token'])).and_return(todoist_client)
    allow(todoist_client).to receive(:create_task).and_return(response
  end

  describe '#perform' do
    context 'when the api token is not configured' do
      it 'does not create a Todoist task' do
        hook = create(:integrations_hook, :todoist, account: account, settings: {})
        expect(Todoist).not_to receive(:new)
        described_class.new(hook: hook, conversation: conversation).perform
      end
    end

    context 'when the api token is configured' do
      it 'creates a task with the conversation summary' do
        create(:message, account: account, conversation: conversation, content: 'hello', message_type: :incoming)

        service.perform
        expect(todoist_client).to have_received(:create_task).with(
          a_string_including(conversation.display_id.to_s),
          any_args
        )
      end
    end

    context 'when Todoist API fails' do
      it 'tracks the exception instead of breaking the conversation flow' do
        allow(todoist_client).to receive(:create_task).and_raise(StandardError, 'API down')
        exception_tracker = instance_double(ChatwootExceptionTracker)
        allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
        allow(exception_tracker).to receive(:capture_exception)

        expect { service.perform }.not_to raise_error
        expect(ChatwootExceptionTracker).to have_received(:new)
      end
    end
  end
end