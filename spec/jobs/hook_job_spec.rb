require 'rails_helper'

RSpec.describe HookJob, type: :job do
  subject(:job) { described_class.perform_later(hook, event_name, event_data) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:event_name) { 'message.created' }
  let(:event_data) { { message: create(:message, account: account) } }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(hook, event_name, event_data)
      .on_queue('integrations')
  end

  context 'when handleable events like message.created' do
    let(:process_service) { double }

    before do
      allow(process_service).to receive(:perform)
    end

    it 'calls Integrations::Slack::SendOnSlackService when its a slack hook' do
      hook = create(:integrations_hook, app_id: 'slack', account: account)
      allow(Integrations::Slack::SendOnSlackService).to receive(:new).and_return(process_service)
      expect(Integrations::Slack::SendOnSlackService).to receive(:new)
      described_class.perform_now(hook, event_name, event_data)
    end

    it 'calls Integrations::Dialogflow::ProcessorService when its a dialogflow intergation' do
      hook = create(:integrations_hook, :dialogflow, inbox: inbox, account: account)
      allow(Integrations::Dialogflow::ProcessorService).to receive(:new).and_return(process_service)
      expect(Integrations::Dialogflow::ProcessorService).to receive(:new)
      described_class.perform_now(hook, event_name, event_data)
    end
  end
end
