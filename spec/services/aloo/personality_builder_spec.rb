# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::PersonalityBuilder do
  let(:assistant) { build(:aloo_assistant) }
  let(:builder) { described_class.new(assistant) }

  describe '#build' do
    it 'includes communication style header' do
      result = builder.build

      expect(result).to include('## Communication Style')
    end

    it 'includes tone prompt' do
      assistant.tone = 'professional'
      result = builder.build

      expect(result).to include(described_class::TONE_PROMPTS['professional'])
    end

    it 'includes formality prompt' do
      assistant.formality = 'high'
      result = builder.build

      expect(result).to include(described_class::FORMALITY_PROMPTS['high'])
    end

    it 'includes empathy prompt' do
      assistant.empathy_level = 'high'
      result = builder.build

      expect(result).to include(described_class::EMPATHY_PROMPTS['high'])
    end

    it 'includes verbosity prompt' do
      assistant.verbosity = 'concise'
      result = builder.build

      expect(result).to include(described_class::VERBOSITY_PROMPTS['concise'])
    end

    it 'includes emoji prompt' do
      assistant.emoji_usage = 'none'
      result = builder.build

      expect(result).to include(described_class::EMOJI_PROMPTS['none'])
    end

    context 'with personality_description' do
      before do
        assistant.personality_description = 'Always be enthusiastic and use exclamation points!'
      end

      it 'includes additional traits section' do
        result = builder.build

        expect(result).to include('## Additional Personality Traits')
        expect(result).to include('Always be enthusiastic and use exclamation points!')
      end
    end

    context 'without personality_description' do
      before do
        assistant.personality_description = nil
      end

      it 'does not include additional traits section' do
        result = builder.build

        expect(result).not_to include('## Additional Personality Traits')
      end
    end

    context 'with custom greeting' do
      before do
        assistant.greeting_style = 'custom'
        assistant.custom_greeting = 'Ahlan wa sahlan!'
      end

      it 'includes greeting section' do
        result = builder.build

        expect(result).to include('Greeting:')
        expect(result).to include('Ahlan wa sahlan!')
      end
    end

    context 'without custom greeting' do
      before do
        assistant.greeting_style = 'warm'
      end

      it 'does not include greeting section' do
        result = builder.build

        expect(result).not_to include('## Greeting')
      end
    end

    context 'with non-English language' do
      before do
        assistant.language = 'fr'
      end

      it 'includes language instruction' do
        result = builder.build

        expect(result).to include('## Language')
        expect(result).to include('Respond in French.')
      end
    end

    context 'with Arabic dialect' do
      before do
        assistant.language = 'ar'
        assistant.dialect = 'EG'
      end

      it 'includes dialect-specific instruction' do
        result = builder.build

        expect(result).to include('## Language')
        expect(result).to include('Egyptian Arabic')
      end
    end

    context 'with English language' do
      before do
        assistant.language = 'en'
        assistant.dialect = nil
      end

      it 'does not include language section' do
        result = builder.build

        expect(result).not_to include('## Language')
      end
    end

    describe 'all tone variations' do
      described_class::TONE_PROMPTS.each do |tone, prompt|
        it "includes correct prompt for #{tone} tone" do
          assistant.tone = tone
          result = builder.build

          expect(result).to include(prompt)
        end
      end
    end

    describe 'all formality variations' do
      described_class::FORMALITY_PROMPTS.each do |level, prompt|
        it "includes correct prompt for #{level} formality" do
          assistant.formality = level
          result = builder.build

          expect(result).to include(prompt)
        end
      end
    end

    describe 'all empathy variations' do
      described_class::EMPATHY_PROMPTS.each do |level, prompt|
        it "includes correct prompt for #{level} empathy" do
          assistant.empathy_level = level
          result = builder.build

          expect(result).to include(prompt)
        end
      end
    end

    describe 'all verbosity variations' do
      described_class::VERBOSITY_PROMPTS.each do |level, prompt|
        it "includes correct prompt for #{level} verbosity" do
          assistant.verbosity = level
          result = builder.build

          expect(result).to include(prompt)
        end
      end
    end

    describe 'all emoji variations' do
      described_class::EMOJI_PROMPTS.each do |level, prompt|
        it "includes correct prompt for #{level} emoji usage" do
          assistant.emoji_usage = level
          result = builder.build

          expect(result).to include(prompt)
        end
      end
    end
  end
end
