require 'rails_helper'

RSpec.describe Crm::Leadsquared::SetupService do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :leadsquared, account: account) }
  let(:service) { described_class.new(hook) }
  let(:base_client) { instance_double(Crm::Leadsquared::Api::BaseClient) }
  let(:activity_client) { instance_double(Crm::Leadsquared::Api::ActivityClient) }

  before do
    allow(Crm::Leadsquared::Api::BaseClient).to receive(:new).and_return(base_client)
    allow(Crm::Leadsquared::Api::ActivityClient).to receive(:new).and_return(activity_client)
  end

  describe '#setup' do
    context 'when fetching activity types fails' do
      before do
        allow(base_client).to receive(:get)
          .with('ProspectActivity.svc/ActivityTypes.Get')
          .and_return({ success: false, error: 'API Error' })
      end

      it 'returns error response' do
        result = service.setup
        expect(result[:success]).to be false
        expect(result[:error]).to eq('API Error')
      end
    end

    context 'when fetching activity types succeeds' do
      let(:started_type) do
        { 'ActivityEventName' => 'Chatwoot Conversation Started', 'ActivityEvent' => 1001 }
      end

      let(:transcript_type) do
        { 'ActivityEventName' => 'Chatwoot Conversation Transcript', 'ActivityEvent' => 1002 }
      end

      context 'when all required types exist' do
        before do
          allow(base_client).to receive(:get)
            .with('ProspectActivity.svc/ActivityTypes.Get')
            .and_return({ success: true, data: [started_type, transcript_type] })
        end

        it 'uses existing activity types and updates hook settings' do
          original_settings = hook.settings.dup
          result = service.setup

          expect(result[:success]).to be true
          expect(result[:activity_codes]).to include(
            'conversation_activity_code' => 1001,
            'transcript_activity_code' => 1002
          )

          # Verify hook settings were merged with existing settings
          updated_settings = hook.reload.settings
          expect(updated_settings).to include(original_settings)
          expect(updated_settings).to include(
            'conversation_activity_code' => 1001,
            'transcript_activity_code' => 1002
          )
        end
      end

      context 'when some activity types need to be created' do
        let(:create_response) do
          { success: true, activity_id: 1002 }
        end

        before do
          allow(base_client).to receive(:get)
            .with('ProspectActivity.svc/ActivityTypes.Get')
            .and_return({ success: true, data: [started_type] })

          allow(activity_client).to receive(:create_activity_type)
            .with(
              name: 'Chatwoot Conversation Transcript',
              score: 0,
              direction: 0
            )
            .and_return(create_response)
        end

        it 'creates missing types and updates hook settings' do
          original_settings = hook.settings.dup
          result = service.setup

          expect(result[:success]).to be true
          expect(result[:activity_codes]).to include(
            'conversation_activity_code' => 1001,
            'transcript_activity_code' => 1002
          )

          # Verify hook settings were merged with existing settings
          updated_settings = hook.reload.settings
          expect(updated_settings).to include(original_settings)
          expect(updated_settings).to include(
            'conversation_activity_code' => 1001,
            'transcript_activity_code' => 1002
          )
        end
      end

      context 'when activity type creation fails' do
        before do
          allow(base_client).to receive(:get)
            .with('ProspectActivity.svc/ActivityTypes.Get')
            .and_return({ success: true, data: [started_type] })

          allow(activity_client).to receive(:create_activity_type)
            .with(anything)
            .and_return({ success: false, error: 'Failed to create activity type' })
        end

        it 'returns error response' do
          result = service.setup
          expect(result[:success]).to be false
          expect(result[:errors]).to include(/Failed to create activity type/)
        end
      end
    end
  end

  describe '#activity_types' do
    it 'defines conversation started activity type' do
      required_types = service.send(:activity_types)
      conversation_type = required_types.find { |t| t[:setting_key] == 'conversation_activity_code' }
      expect(conversation_type).to include(
        name: 'Chatwoot Conversation Started',
        score: 0,
        direction: 0,
        setting_key: 'conversation_activity_code'
      )
    end

    it 'defines transcript activity type' do
      required_types = service.send(:activity_types)
      transcript_type = required_types.find { |t| t[:setting_key] == 'transcript_activity_code' }
      expect(transcript_type).to include(
        name: 'Chatwoot Conversation Transcript',
        score: 0,
        direction: 0,
        setting_key: 'transcript_activity_code'
      )
    end
  end
end
