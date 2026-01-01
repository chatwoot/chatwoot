# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MemoryExtractorAgent do
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

    it 'includes memory types' do
      prompt = agent.system_prompt

      expect(prompt).to include('preference')
      expect(prompt).to include('commitment')
      expect(prompt).to include('procedure')
      expect(prompt).to include('faq')
    end

    it 'includes extraction guidelines' do
      prompt = agent.system_prompt

      expect(prompt).to include('memory extraction agent')
      expect(prompt).to include('genuinely useful information')
    end
  end

  describe '#user_prompt' do
    it 'includes transcript' do
      agent = described_class.new(transcript: 'Customer: Hi\nAgent: Hello')
      prompt = agent.user_prompt

      expect(prompt).to include('Customer: Hi')
      expect(prompt).to include('Agent: Hello')
    end

    it 'includes resolution status' do
      agent = described_class.new(transcript: 'Test', resolution_status: 'resolved')
      prompt = agent.user_prompt

      expect(prompt).to include('resolved')
    end

    it 'includes max_memories limit' do
      agent = described_class.new(transcript: 'Test', max_memories: 5)
      prompt = agent.user_prompt

      expect(prompt).to include('5 memories')
    end

    context 'with resolved status' do
      it 'includes resolution context' do
        agent = described_class.new(transcript: 'Test', resolution_status: 'resolved')
        prompt = agent.user_prompt

        expect(prompt).to include('successful patterns')
      end
    end

    context 'with open status' do
      it 'includes open context' do
        agent = described_class.new(transcript: 'Test', resolution_status: 'open')
        prompt = agent.user_prompt

        expect(prompt).to include('unresolved issues')
      end
    end
  end

  describe '#schema' do
    let(:agent) { described_class.new(transcript: 'Test') }

    it 'defines memories array structure' do
      schema = agent.schema

      expect(schema).not_to be_nil
    end
  end

  describe 'MEMORY_TYPES constant' do
    it 'includes all expected types' do
      types = described_class::MEMORY_TYPES.keys

      expect(types).to include('preference', 'commitment', 'decision', 'correction')
      expect(types).to include('procedure', 'faq', 'insight', 'gap')
    end

    it 'has descriptions for each type' do
      described_class::MEMORY_TYPES.each do |type, description|
        expect(description).to be_a(String)
        expect(description.length).to be > 10
      end
    end
  end

  describe '.call' do
    context 'with dry_run: true' do
      it 'returns prompts without API call' do
        result = described_class.call(
          transcript: 'Customer: I prefer email contact\nAgent: Noted!',
          resolution_status: 'resolved',
          dry_run: true
        )

        expect(result).to respond_to(:content)
        expect(result).to respond_to(:success?)
      end

      it 'includes transcript in user_prompt' do
        result = described_class.call(
          transcript: 'Customer asked about billing',
          dry_run: true
        )

        expect(result.content[:user_prompt]).to include('Customer asked about billing')
      end
    end
  end
end
