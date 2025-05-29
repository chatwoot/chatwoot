require 'rails_helper'

RSpec.describe Internal::AccountAnalysis::ContentEvaluatorService do
  let(:service) { described_class.new }
  let(:content) { 'This is some test content' }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
  end

  describe '#evaluate' do
    context 'when content is present' do
      let(:llm_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => {
                  'threat_level' => 'low',
                  'threat_summary' => 'No significant threats detected',
                  'detected_threats' => ['minor_concern'],
                  'illegal_activities_detected' => false,
                  'recommendation' => 'approve'
                }.to_json
              }
            }
          ]
        }
      end

      before do
        allow(service).to receive(:send_to_llm).and_return(llm_response)
        allow(Rails.logger).to receive(:info)
      end

      it 'returns the evaluation results' do
        result = service.evaluate(content)

        expect(result).to include(
          'threat_level' => 'low',
          'threat_summary' => 'No significant threats detected',
          'detected_threats' => ['minor_concern'],
          'illegal_activities_detected' => false,
          'recommendation' => 'approve'
        )
      end

      it 'logs the evaluation results' do
        service.evaluate(content)

        expect(Rails.logger).to have_received(:info).with('LLM evaluation - Level: low, Illegal activities: false')
      end
    end

    context 'when content is blank' do
      let(:blank_content) { '' }

      it 'returns the default evaluation without calling the LLM' do
        expect(service).not_to receive(:send_to_llm)

        result = service.evaluate(blank_content)

        expect(result).to include(
          'threat_level' => 'unknown',
          'threat_summary' => 'Failed to complete content evaluation',
          'detected_threats' => [],
          'illegal_activities_detected' => false,
          'recommendation' => 'review'
        )
      end
    end

    context 'when LLM response is nil' do
      before do
        allow(service).to receive(:send_to_llm).and_return(nil)
      end

      it 'returns the default evaluation' do
        result = service.evaluate(content)

        expect(result).to include(
          'threat_level' => 'unknown',
          'threat_summary' => 'Failed to complete content evaluation',
          'detected_threats' => [],
          'illegal_activities_detected' => false,
          'recommendation' => 'review'
        )
      end
    end

    context 'when error occurs during evaluation' do
      before do
        allow(service).to receive(:send_to_llm).and_raise(StandardError.new('Test error'))
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error and returns default evaluation with error type' do
        result = service.evaluate(content)

        expect(Rails.logger).to have_received(:error).with('Error evaluating content: Test error')
        expect(result).to include(
          'threat_level' => 'unknown',
          'threat_summary' => 'Failed to complete content evaluation',
          'detected_threats' => ['evaluation_failure'],
          'illegal_activities_detected' => false,
          'recommendation' => 'review'
        )
      end
    end
  end
end
