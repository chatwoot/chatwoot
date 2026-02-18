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

    context 'when llm returns inconsistent marketing classification and high score' do
      it 'normalizes score to avoid misleading utility fit' do
        allow(llm_service).to receive(:perform).and_return({
                                                              classification: 'LIKELY_MARKETING',
                                                              score: 8,
                                                              confidence: 'HIGH',
                                                              reasons: ['Promotional wording detected'],
                                                              optimized_message: 'Your support request has been closed.',
                                                              positive_points: [],
                                                              non_compliance_points: ['Promotional wording may cause Meta to classify this as Marketing.'],
                                                              score_justification: 'Promotional wording present',
                                                              criteria: {
                                                                trigger: true,
                                                                transactional_content: true,
                                                                marketing_prohibition: false,
                                                                prohibited_content: true,
                                                                clarity_and_utility: true
                                                              }
                                                            })

        message = 'Your case is closed. Don’t miss our limited-time premium offer. Rate us below.'
        result = described_class.new(account: account, inbox: inbox, message: message, language: 'en').perform

        expect(result[:classification]).to eq('LIKELY_MARKETING')
        expect(result[:score]).to be <= 4
      end
    end
  end
end
