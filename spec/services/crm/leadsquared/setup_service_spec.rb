require 'rails_helper'

RSpec.describe Crm::Leadsquared::SetupService do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :leadsquared, account: account) }
  let(:service) { described_class.new(hook) }
  let(:base_client) { instance_double(Crm::Leadsquared::Api::BaseClient) }

  before do
    allow(Crm::Leadsquared::Api::BaseClient).to receive(:new).and_return(base_client)
  end

  describe '#setup' do
    context 'when fetching activity types fails' do
      before do
        allow(base_client).to receive(:get)
          .with('/v2/ProspectActivity/Types')
          .and_return({ success: false, error: 'API Error' })
      end

      it 'returns error response' do
        result = service.setup
        expect(result[:success]).to be false
        expect(result[:error]).to eq('API Error')
      end
    end

    context 'when fetching activity types succeeds' do
      let(:existing_types) do
        [
          {
            'Name' => 'Chatwoot Conversation Started',
            'Value' => 1001,
            'Score' => 10,
            'Direction' => 0,
            'IsActive' => true
          }
        ]
      end

      before do
        allow(base_client).to receive(:get)
          .with('/v2/ProspectActivity/Types')
          .and_return({ success: true, data: existing_types })
      end

      context 'when all required types exist' do
        let(:existing_types) do
          [
            {
              'Name' => 'Chatwoot Conversation Started',
              'Value' => 1001,
              'Score' => 10,
              'Direction' => 0,
              'IsActive' => true
            },
            {
              'Name' => 'Chatwoot Conversation Transcript',
              'Value' => 1002,
              'Score' => 5,
              'Direction' => 0,
              'IsActive' => true
            }
          ]
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
          {
            success: true,
            data: {
              'Status' => 'Success',
              'Message' => {
                'ActivityEventId' => 1002
              }
            }
          }
        end

        before do
          allow(base_client).to receive(:post)
            .with('/v2/ProspectActivity/Type.Create', {}, {
                    'Name' => 'Chatwoot Conversation Transcript',
                    'Score' => 5,
                    'Direction' => 0,
                    'IsActive' => true
                  })
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
          allow(base_client).to receive(:post)
            .with('/v2/ProspectActivity/Type.Create', anything, anything)
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

  describe 'REQUIRED_ACTIVITY_TYPES' do
    subject(:required_types) { described_class::REQUIRED_ACTIVITY_TYPES }

    it 'defines conversation started activity type' do
      conversation_type = required_types.find { |t| t[:setting_key] == 'conversation_activity_code' }
      expect(conversation_type).to include(
        name: 'Chatwoot Conversation Started',
        score: 10,
        direction: 0
      )
    end

    it 'defines transcript activity type' do
      transcript_type = required_types.find { |t| t[:setting_key] == 'transcript_activity_code' }
      expect(transcript_type).to include(
        name: 'Chatwoot Conversation Transcript',
        score: 5,
        direction: 0
      )
    end
  end
end
