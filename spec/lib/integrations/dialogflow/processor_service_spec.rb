require 'rails_helper'

describe Integrations::Dialogflow::ProcessorService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:hook) { create(:integrations_hook, :dialogflow, inbox: inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, status: :pending) }
  let(:message) { create(:message, account: account, conversation: conversation) }
  let(:template_message) { create(:message, account: account, conversation: conversation, message_type: :template, content: 'Bot message') }
  let(:event_name) { 'message.created' }
  let(:event_data) { { message: message } }
  let(:dialogflow_text_double) { double }

  describe '#perform' do
    let(:dialogflow_service) { double }
    let(:dialogflow_response) do
      ActiveSupport::HashWithIndifferentAccess.new(
        fulfillment_messages: [
          { text: dialogflow_text_double }
        ]
      )
    end

    let(:processor) { described_class.new(event_name: event_name, hook: hook, event_data: event_data) }

    before do
      allow(dialogflow_service).to receive(:query_result).and_return(dialogflow_response)
      allow(processor).to receive(:get_response).and_return(dialogflow_service)
      allow(dialogflow_text_double).to receive(:to_h).and_return({ text: ['hello payload'] })
    end

    context 'when valid message and dialogflow returns fullfillment text' do
      it 'creates the response message' do
        processor.perform
        expect(conversation.reload.messages.last.content).to eql('hello payload')
      end
    end

    context 'when invalid message and dialogflow returns empty block' do
      it 'will not create the response message' do
        event_data = { message: template_message }
        processor = described_class.new(event_name: event_name, hook: hook, event_data: event_data)
        processor.perform
        expect(conversation.reload.messages.last.content).not_to eql('hello payload')
      end
    end

    context 'when dilogflow raises exception' do
      it 'tracks hook into exception tracked' do
        last_message = conversation.reload.messages.last.content
        allow(dialogflow_service).to receive(:query_result).and_raise(StandardError)
        processor.perform
        expect(conversation.reload.messages.last.content).to eql(last_message)
      end
    end

    context 'when dilogflow settings are not present' do
      it 'will get empty response' do
        last_count = conversation.reload.messages.count
        allow(processor).to receive(:get_response).and_return({})
        hook.settings = { 'project_id' => 'something_invalid', 'credentials' => {} }
        hook.save!
        processor.perform

        expect(conversation.reload.messages.count).to eql(last_count)
      end
    end

    context 'when dialogflow returns fullfillment text to be empty' do
      let(:dialogflow_response) do
        ActiveSupport::HashWithIndifferentAccess.new(
          fulfillment_messages: [{ payload: { content: 'hello payload random' } }]
        )
      end

      it 'creates the response message based on fulfillment messages' do
        processor.perform
        expect(conversation.reload.messages.last.content).to eql('hello payload random')
      end
    end

    context 'when dialogflow returns action' do
      let(:dialogflow_response) do
        ActiveSupport::HashWithIndifferentAccess.new(
          fulfillment_messages: [{ payload: { action: 'handoff' } }]
        )
      end

      it 'handsoff the conversation to agent' do
        processor.perform
        expect(conversation.status).to eql('open')
      end
    end

    context 'when dialogflow returns action and messages if available' do
      let(:dialogflow_response) do
        ActiveSupport::HashWithIndifferentAccess.new(
          fulfillment_messages: [{ payload: { action: 'handoff' } }, { text: dialogflow_text_double }]
        )
      end

      it 'handsoff the conversation to agent' do
        processor.perform
        expect(conversation.reload.status).to eql('open')
        expect(conversation.messages.last.content).to eql('hello payload')
      end
    end

    context 'when dialogflow returns resolve action' do
      let(:dialogflow_response) do
        ActiveSupport::HashWithIndifferentAccess.new(
          fulfillment_messages: [{ payload: { action: 'resolve' } }, { text: dialogflow_text_double }]
        )
      end

      it 'resolves the conversation without moving it to an agent' do
        processor.perform
        expect(conversation.reload.status).to eql('resolved')
        expect(conversation.messages.last.content).to eql('hello payload')
      end
    end

    context 'when conversation is not bot' do
      let(:conversation) { create(:conversation, account: account, status: :open) }

      it 'returns nil' do
        expect(processor.perform).to be_nil
      end
    end

    context 'when message is private' do
      let(:message) { create(:message, account: account, conversation: conversation, private: true) }

      it 'returns nil' do
        expect(processor.perform).to be_nil
      end
    end

    context 'when message updated' do
      let(:message) do
        create(:message, account: account, conversation: conversation, private: true,
                         submitted_values: [{ 'title' => 'Support', 'value' => 'selected_gas' }])
      end
      let(:event_name) { 'message.updated' }

      it 'returns submitted value for message content' do
        expect(processor.send(:message_content, message)).to eql('selected_gas')
      end
    end
  end

  describe '#get_response' do
    let(:google_dialogflow) { Google::Cloud::Dialogflow::V2::Sessions::Client }
    let(:session_client) { double }
    let(:session) { double }
    let(:query_input) { { text: { text: message, language_code: 'en-US' } } }
    let(:processor) { described_class.new(event_name: event_name, hook: hook, event_data: event_data) }

    before do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => 'creds' })
      allow(google_dialogflow).to receive(:new).and_return(session_client)
      allow(session_client).to receive(:detect_intent).and_return({ session: session, query_input: query_input })
    end

    it 'returns intended response' do
      response = processor.send(:get_response, conversation.contact_inbox.source_id, message.content)
      expect(response[:query_input][:text][:text]).to eq(message)
      expect(response[:query_input][:text][:language_code]).to eq('en-US')
    end

    it 'disables the hook if permission errors are thrown' do
      allow(session_client).to receive(:detect_intent).and_raise(Google::Cloud::PermissionDeniedError)

      expect { processor.send(:get_response, conversation.contact_inbox.source_id, message.content) }
        .to change(hook, :status).from('enabled').to('disabled')
    end
  end

  describe '#configure_dialogflow_client_defaults' do
    let(:google_dialogflow) { Google::Cloud::Dialogflow::V2::Sessions::Client }
    let(:processor) { described_class.new(event_name: event_name, hook: hook, event_data: event_data) }

    it 'sets global endpoint when region is global' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => 'global' })
      config = OpenStruct.new
      expect(google_dialogflow).to receive(:configure).and_yield(config)

      processor.send(:configure_dialogflow_client_defaults)
      expect(config.endpoint).to eq('dialogflow.googleapis.com')
    end

    it 'sets global endpoint when region is not specified (defaults to global)' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {} })
      config = OpenStruct.new
      expect(google_dialogflow).to receive(:configure).and_yield(config)

      processor.send(:configure_dialogflow_client_defaults)
      expect(config.endpoint).to eq('dialogflow.googleapis.com')
    end

    it 'sets endpoint when region is not global' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => 'europe-west1' })
      config = OpenStruct.new
      expect(google_dialogflow).to receive(:configure).and_yield(config)

      processor.send(:configure_dialogflow_client_defaults)
      expect(config.endpoint).to eq('europe-west1-dialogflow.googleapis.com')
    end

    it 'sets correct endpoint for different regions' do
      %w[europe-west1 europe-west2 australia-southeast1 asia-northeast1].each do |region|
        hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => region })
        config = OpenStruct.new
        expect(google_dialogflow).to receive(:configure).and_yield(config)

        processor.send(:configure_dialogflow_client_defaults)
        expect(config.endpoint).to eq("#{region}-dialogflow.googleapis.com")
      end
    end

    it 'handles empty region value correctly (defaults to global)' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => '' })
      config = OpenStruct.new
      expect(google_dialogflow).to receive(:configure).and_yield(config)

      processor.send(:configure_dialogflow_client_defaults)
      expect(config.endpoint).to eq('dialogflow.googleapis.com')
    end

    it 'handles nil region value correctly (defaults to global)' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => nil })
      config = OpenStruct.new
      expect(google_dialogflow).to receive(:configure).and_yield(config)

      processor.send(:configure_dialogflow_client_defaults)
      expect(config.endpoint).to eq('dialogflow.googleapis.com')
    end
  end

  describe '#dialogflow_endpoint' do
    let(:processor) { described_class.new(event_name: event_name, hook: hook, event_data: event_data) }

    it 'returns global endpoint for global region' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => 'global' })
      expect(processor.send(:dialogflow_endpoint)).to eq('dialogflow.googleapis.com')
    end

    it 'returns global endpoint when region is not specified' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {} })
      expect(processor.send(:dialogflow_endpoint)).to eq('dialogflow.googleapis.com')
    end

    it 'returns correct endpoint for non-global regions' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => 'europe-west1' })
      expect(processor.send(:dialogflow_endpoint)).to eq('europe-west1-dialogflow.googleapis.com')
    end

    it 'handles empty string region' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => '  ' })
      expect(processor.send(:dialogflow_endpoint)).to eq('dialogflow.googleapis.com')
    end
  end

  describe '#normalized_region' do
    let(:processor) { described_class.new(event_name: event_name, hook: hook, event_data: event_data) }

    it 'returns global for blank region' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => '' })
      expect(processor.send(:normalized_region)).to eq('global')
    end

    it 'returns global for nil region' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {} })
      expect(processor.send(:normalized_region)).to eq('global')
    end

    it 'returns global for whitespace region' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => '  ' })
      expect(processor.send(:normalized_region)).to eq('global')
    end

    it 'returns specified region when provided' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => 'europe-west1' })
      expect(processor.send(:normalized_region)).to eq('europe-west1')
    end

    it 'trims whitespace from region' do
      hook.update(settings: { 'project_id' => 'test', 'credentials' => {}, 'region' => '  asia-northeast1  ' })
      expect(processor.send(:normalized_region)).to eq('asia-northeast1')
    end
  end

  describe '#detect_intent' do
    let(:processor) { described_class.new(event_name: event_name, hook: hook, event_data: event_data) }
    let(:mock_client) { instance_double(Google::Cloud::Dialogflow::V2::Sessions::Client) }

    before do
      allow(Google::Cloud::Dialogflow::V2::Sessions::Client).to receive(:new).and_return(mock_client)
    end

    it 'builds session path without location for global region' do
      hook.update(settings: { 'project_id' => 'test-project', 'credentials' => {}, 'region' => 'global' })
      expected_session = 'projects/test-project/agent/sessions/test-session'

      expect(mock_client).to receive(:detect_intent).with(
        session: expected_session,
        query_input: { text: { text: 'Hello', language_code: 'en-US' } }
      )

      processor.send(:detect_intent, 'test-session', 'Hello')
    end

    it 'builds session path with specified location for regional deployment' do
      hook.update(settings: { 'project_id' => 'test-project', 'credentials' => {}, 'region' => 'europe-west1' })
      expected_session = 'projects/test-project/locations/europe-west1/agent/sessions/test-session'

      expect(mock_client).to receive(:detect_intent).with(
        session: expected_session,
        query_input: { text: { text: 'Hello', language_code: 'en-US' } }
      )

      processor.send(:detect_intent, 'test-session', 'Hello')
    end

    it 'defaults to global session path when region is not specified' do
      hook.update(settings: { 'project_id' => 'test-project', 'credentials' => {} })
      expected_session = 'projects/test-project/agent/sessions/test-session'

      expect(mock_client).to receive(:detect_intent).with(
        session: expected_session,
        query_input: { text: { text: 'Hello', language_code: 'en-US' } }
      )

      processor.send(:detect_intent, 'test-session', 'Hello')
    end
  end

  describe '#build_session_path' do
    let(:processor) { described_class.new(event_name: event_name, hook: hook, event_data: event_data) }

    it 'builds session path without location for global region' do
      hook.update(settings: { 'project_id' => 'test-project', 'credentials' => {}, 'region' => 'global' })
      expected_path = 'projects/test-project/agent/sessions/test-session'
      expect(processor.send(:build_session_path, 'test-session')).to eq(expected_path)
    end

    it 'builds session path with location for regional deployment' do
      hook.update(settings: { 'project_id' => 'test-project', 'credentials' => {}, 'region' => 'europe-west1' })
      expected_path = 'projects/test-project/locations/europe-west1/agent/sessions/test-session'
      expect(processor.send(:build_session_path, 'test-session')).to eq(expected_path)
    end

    it 'defaults to global session path when region is not specified' do
      hook.update(settings: { 'project_id' => 'test-project', 'credentials' => {} })
      expected_path = 'projects/test-project/agent/sessions/test-session'
      expect(processor.send(:build_session_path, 'test-session')).to eq(expected_path)
    end

    it 'handles different project IDs correctly' do
      hook.update(settings: { 'project_id' => 'my-awesome-project-123', 'credentials' => {}, 'region' => 'asia-northeast1' })
      expected_path = 'projects/my-awesome-project-123/locations/asia-northeast1/agent/sessions/session-abc-123'
      expect(processor.send(:build_session_path, 'session-abc-123')).to eq(expected_path)
    end
  end
end
