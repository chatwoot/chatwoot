require 'rails_helper'

RSpec.describe CsatTemplateUtilityAnalysisService do
  let(:account) { build_stubbed(:account) }
  let(:inbox) { build_stubbed(:inbox) }
  let(:llm_service) { instance_double(Captain::CsatUtilityAnalysisService) }

  before do
    allow(Captain::CsatUtilityAnalysisService).to receive(:new).and_return(llm_service)
    allow(llm_service).to receive(:perform).and_return({ error: 'LLM unavailable' })
  end

  describe '#perform' do
    context 'when message is utility-compatible' do
      it 'returns likely utility classification and keeps original message' do
        message = 'Your support request has been closed. If you still need help, reply to this message.'
        result = described_class.new(account: account, inbox: inbox, message: message, language: 'en').perform

        expect(result[:classification]).to eq('LIKELY_UTILITY')
        expect(result[:criteria]).to include(
          trigger: true,
          transactional_content: true,
          marketing_prohibition: true,
          prohibited_content: true,
          clarity_and_utility: true
        )
        expect(result[:positive_points]).not_to be_empty
        expect(result[:score_justification]).to be_present
        expect(result[:optimized_message]).to eq(message)
      end
    end

    context 'when message contains marketing intent' do
      it 'returns likely marketing classification with utility-safe rewrite' do
        message = 'Please rate us and check out our special offer with a discount.'
        result = described_class.new(account: account, inbox: inbox, message: message, language: 'en').perform

        expect(result[:classification]).to eq('LIKELY_MARKETING')
        expect(result[:non_compliance_points]).not_to be_empty
        expect(result[:optimized_message]).to include('support request')
        expect(result[:optimized_message]).to include('reply to this message')
      end
    end

    context 'when language is Spanish and fallback rewrite is used' do
      it 'returns Spanish rewrite content' do
        message = 'Tu caso está cerrado. Califícanos y no te pierdas nuestra oferta.'
        result = described_class.new(account: account, inbox: inbox, message: message, language: 'es').perform

        expect(result[:optimized_message]).to include('Tu solicitud de soporte ha sido cerrada.')
        expect(result[:optimized_message]).to include('Si aún necesitas ayuda')
      end
    end
  end
end
