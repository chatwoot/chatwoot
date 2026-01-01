# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FaqGeneratorAgent do
  describe 'configuration' do
    it 'uses gemini model' do
      expect(described_class.model).to eq('gemini-2.0-flash')
    end

    it 'has temperature of 0.5' do
      expect(described_class.temperature).to eq(0.5)
    end
  end

  describe '#system_prompt' do
    let(:agent) { described_class.new(transcript: 'Test transcript') }

    it 'includes FAQ generation guidelines' do
      prompt = agent.system_prompt

      expect(prompt).to include('FAQ generator')
      expect(prompt).to include('resolved customer support conversations')
    end

    it 'includes quality guidelines' do
      prompt = agent.system_prompt

      expect(prompt).to include('likely to be asked by other customers')
      expect(prompt).to include('successfully answered')
      expect(prompt).to include('generalizable')
    end
  end

  describe '#user_prompt' do
    it 'includes transcript' do
      agent = described_class.new(transcript: 'Customer: How do I reset?\nAgent: Click the button.')
      prompt = agent.user_prompt

      expect(prompt).to include('Customer: How do I reset?')
      expect(prompt).to include('Agent: Click the button.')
    end

    it 'includes max_faqs limit' do
      agent = described_class.new(transcript: 'Test', max_faqs: 5)
      prompt = agent.user_prompt

      expect(prompt).to include('5 FAQs')
    end

    it 'uses default max_faqs of 3' do
      agent = described_class.new(transcript: 'Test')
      prompt = agent.user_prompt

      expect(prompt).to include('3 FAQs')
    end
  end

  describe '#schema' do
    let(:agent) { described_class.new(transcript: 'Test') }

    it 'defines faqs array structure' do
      schema = agent.schema

      expect(schema).not_to be_nil
    end
  end

  describe '.call' do
    context 'with dry_run: true' do
      it 'returns prompts without API call' do
        result = described_class.call(
          transcript: 'Customer: What is return policy?\nAgent: 30 days.',
          dry_run: true
        )

        expect(result).to respond_to(:content)
        expect(result).to respond_to(:success?)
      end

      it 'includes system prompt with FAQ guidelines' do
        result = described_class.call(
          transcript: 'Test conversation',
          dry_run: true
        )

        expect(result.content[:system_prompt]).to include('FAQ')
      end

      it 'includes transcript in user_prompt' do
        result = described_class.call(
          transcript: 'Customer: Payment question\nAgent: Use card',
          dry_run: true
        )

        expect(result.content[:user_prompt]).to include('Payment question')
      end
    end
  end
end
