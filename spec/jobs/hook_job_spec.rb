require 'rails_helper'

RSpec.describe HookJob do
  subject(:job) { described_class.perform_later(hook, event_name, event_data) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:event_name) { 'message.created' }
  let(:event_data) { { message: create(:message, account: account, content: 'muchas muchas gracias', message_type: :incoming) } }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(hook, event_name, event_data)
      .on_queue('medium')
  end

  context 'when the hook is disabled' do
    it 'does not execute the job' do
      hook = create(:integrations_hook, status: 'disabled', account: account)
      allow(SendOnSlackJob).to receive(:perform_later)
      allow(Integrations::Dialogflow::ProcessorService).to receive(:new)
      allow(Integrations::GoogleTranslate::DetectLanguageService).to receive(:new)

      expect(SendOnSlackJob).not_to receive(:perform_later)
      expect(Integrations::GoogleTranslate::DetectLanguageService).not_to receive(:new)
      expect(Integrations::Dialogflow::ProcessorService).not_to receive(:new)
      described_class.perform_now(hook, event_name, event_data)
    end
  end

  context 'when handleable events like message.created' do
    let(:process_service) { double }

    before do
      allow(process_service).to receive(:perform)
    end

    it 'calls SendOnSlackJob when its a slack hook' do
      hook = create(:integrations_hook, app_id: 'slack', account: account)
      allow(SendOnSlackJob).to receive(:perform_later).and_return(process_service)
      expect(SendOnSlackJob).to receive(:perform_later).with(event_data[:message], hook)
      described_class.perform_now(hook, event_name, event_data)
    end

    it 'calls SendOnSlackJob when its a slack hook for message with attachments' do
      event_data = { message: create(:message, :with_attachment, account: account) }
      hook = create(:integrations_hook, app_id: 'slack', account: account)
      allow(SendOnSlackJob).to receive(:set).with(wait: 2.seconds).and_return(SendOnSlackJob)
      allow(SendOnSlackJob).to receive(:perform_later).and_return(process_service)
      expect(SendOnSlackJob).to receive(:perform_later).with(event_data[:message], hook)
      described_class.perform_now(hook, event_name, event_data)
    end

    it 'calls Integrations::Dialogflow::ProcessorService when its a dialogflow intergation' do
      hook = create(:integrations_hook, :dialogflow, inbox: inbox, account: account)
      allow(Integrations::Dialogflow::ProcessorService).to receive(:new).and_return(process_service)
      expect(Integrations::Dialogflow::ProcessorService).to receive(:new).with(event_name: event_name, hook: hook, event_data: event_data)
      described_class.perform_now(hook, event_name, event_data)
    end

    it 'calls Conversations::DetectLanguageJob when its a google_translate intergation' do
      hook = create(:integrations_hook, :google_translate, account: account)
      allow(Integrations::GoogleTranslate::DetectLanguageService).to receive(:new).and_return(process_service)
      expect(Integrations::GoogleTranslate::DetectLanguageService).to receive(:new).with(hook: hook, message: event_data[:message])
      described_class.perform_now(hook, event_name, event_data)
    end
  end
end
