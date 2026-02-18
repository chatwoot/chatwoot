require 'rails_helper'

RSpec.describe Captain::CsatUtilityAnalysisService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account, message: 'Test message', language: 'en', baseline: {}) }

  describe '#perform' do
    before do
      allow(account).to receive(:feature_enabled?).and_call_original
      allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
      allow(service).to receive(:make_api_call).and_return({
                                                             message: '{"classification":"LIKELY_UTILITY","optimized_message":"Utility-safe message"}'
                                                           })
    end

    it 'returns parsed payload and preserves raw message for usage metering' do
      result = service.perform

      expect(result[:classification]).to eq('LIKELY_UTILITY')
      expect(result[:optimized_message]).to eq('Utility-safe message')
      expect(result[:message]).to eq('{"classification":"LIKELY_UTILITY","optimized_message":"Utility-safe message"}')
    end
  end
end
