require 'rails_helper'

describe Digitaltolk::SaveQualityScoreService do
  subject { described_class.new(message, ActionController::Parameters.new(params)) }

  let(:message) { create(:message) }

  let(:params) do
    {
      quality_score: {
        qualityCheckResponse: {
          checks: {
            customer_centricity_check: {
              score: 85,
              passed: false
            },
            language_and_grammar_check: {
              score: 95,
              passed: true
            },
            quality_check: {
              score: 90,
              passed: true
            }
          }
        }
      }
    }
  end

  describe '#perform' do
    context 'when message is present' do
      it 'saves the quality scores' do
        expect { subject.perform }.to change(MessageQualityScore, :count)
      end

      it 'updates the quality score' do
        create(:message_quality_score, message: message, scores: {})
        subject.perform
        message_quality_score = MessageQualityScore.last
        expect(message_quality_score.scores).to eq(
          {
            'customer_centricity_check' => { 'passed' => false, 'score' => 85 },
            'language_and_grammar_check' => { 'passed' => true, 'score' => 95 },
            'quality_check' => { 'passed' => true, 'score' => 90 }
          }
        )
      end
    end

    context 'when message is not present' do
      let(:message) { nil }

      it 'does not save the quality scores' do
        expect { subject.perform }.not_to change(MessageQualityScore, :count)
      end
    end

    context 'when quality score is not present' do
      let(:params) { {} }

      it 'does not save the quality scores' do
        expect { subject.perform }.not_to change(MessageQualityScore, :count)
      end
    end
  end
end
