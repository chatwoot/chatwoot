require 'rails_helper'

RSpec.describe Internal::AccountAnalysis::ContentEvaluatorService do
  let(:service) { described_class.new }
  let(:content) { 'This is some test content' }
  let(:mock_moderation_result) do
    instance_double(
      RubyLLM::Moderation,
      flagged?: false,
      flagged_categories: [],
      category_scores: {}
    )
  end

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(RubyLLM).to receive(:moderate).and_return(mock_moderation_result)
  end

  describe '#evaluate' do
    context 'when content is safe' do
      it 'returns safe evaluation with approval recommendation' do
        result = service.evaluate(content)

        expect(result).to include(
          'threat_level' => 'safe',
          'threat_summary' => 'No threats detected',
          'detected_threats' => [],
          'illegal_activities_detected' => false,
          'recommendation' => 'approve'
        )
      end

      it 'logs the evaluation results' do
        expect(Rails.logger).to receive(:info).with('Moderation evaluation - Level: safe, Threats: ')
        service.evaluate(content)
      end
    end

    context 'when content is flagged' do
      let(:mock_moderation_result) do
        instance_double(
          RubyLLM::Moderation,
          flagged?: true,
          flagged_categories: %w[harassment hate],
          category_scores: { 'harassment' => 0.6, 'hate' => 0.3 }
        )
      end

      it 'returns flagged evaluation with review recommendation' do
        result = service.evaluate(content)

        expect(result).to include(
          'threat_level' => 'high',
          'threat_summary' => 'Content flagged for: harassment, hate',
          'detected_threats' => %w[harassment hate],
          'illegal_activities_detected' => false,
          'recommendation' => 'review'
        )
      end
    end

    context 'when content contains violence' do
      let(:mock_moderation_result) do
        instance_double(
          RubyLLM::Moderation,
          flagged?: true,
          flagged_categories: ['violence'],
          category_scores: { 'violence' => 0.9 }
        )
      end

      it 'marks illegal activities detected for violence' do
        result = service.evaluate(content)

        expect(result['illegal_activities_detected']).to be true
        expect(result['threat_level']).to eq('critical')
      end
    end

    context 'when content contains self-harm' do
      let(:mock_moderation_result) do
        instance_double(
          RubyLLM::Moderation,
          flagged?: true,
          flagged_categories: ['self-harm'],
          category_scores: { 'self-harm' => 0.85 }
        )
      end

      it 'marks illegal activities detected for self-harm' do
        result = service.evaluate(content)

        expect(result['illegal_activities_detected']).to be true
      end
    end

    context 'when content is blank' do
      let(:blank_content) { '' }

      it 'returns default evaluation without calling moderation API' do
        expect(RubyLLM).not_to receive(:moderate)

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

    context 'when error occurs during evaluation' do
      before do
        allow(RubyLLM).to receive(:moderate).and_raise(StandardError.new('Test error'))
      end

      it 'logs error and returns default evaluation with error type' do
        expect(Rails.logger).to receive(:error).with('Error evaluating content: Test error')

        result = service.evaluate(content)

        expect(result).to include(
          'threat_level' => 'unknown',
          'threat_summary' => 'Failed to complete content evaluation',
          'detected_threats' => ['evaluation_failure'],
          'illegal_activities_detected' => false,
          'recommendation' => 'review'
        )
      end
    end

    context 'with threat level determination' do
      it 'returns critical for scores >= 0.8' do
        mock_result = instance_double(
          RubyLLM::Moderation,
          flagged?: true,
          flagged_categories: ['harassment'],
          category_scores: { 'harassment' => 0.85 }
        )
        allow(RubyLLM).to receive(:moderate).and_return(mock_result)

        result = service.evaluate(content)
        expect(result['threat_level']).to eq('critical')
      end

      it 'returns high for scores between 0.5 and 0.8' do
        mock_result = instance_double(
          RubyLLM::Moderation,
          flagged?: true,
          flagged_categories: ['harassment'],
          category_scores: { 'harassment' => 0.65 }
        )
        allow(RubyLLM).to receive(:moderate).and_return(mock_result)

        result = service.evaluate(content)
        expect(result['threat_level']).to eq('high')
      end

      it 'returns medium for scores between 0.2 and 0.5' do
        mock_result = instance_double(
          RubyLLM::Moderation,
          flagged?: true,
          flagged_categories: ['harassment'],
          category_scores: { 'harassment' => 0.35 }
        )
        allow(RubyLLM).to receive(:moderate).and_return(mock_result)

        result = service.evaluate(content)
        expect(result['threat_level']).to eq('medium')
      end

      it 'returns low for scores below 0.2' do
        mock_result = instance_double(
          RubyLLM::Moderation,
          flagged?: true,
          flagged_categories: ['harassment'],
          category_scores: { 'harassment' => 0.15 }
        )
        allow(RubyLLM).to receive(:moderate).and_return(mock_result)

        result = service.evaluate(content)
        expect(result['threat_level']).to eq('low')
      end
    end

    context 'with content truncation' do
      let(:long_content) { 'a' * 15_000 }

      it 'truncates content to 10000 characters before sending to moderation' do
        expect(RubyLLM).to receive(:moderate).with('a' * 10_000).and_return(mock_moderation_result)
        service.evaluate(long_content)
      end
    end
  end
end
