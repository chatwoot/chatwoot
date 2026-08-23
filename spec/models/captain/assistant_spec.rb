# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Assistant do
  describe '#max_turns' do
    it 'falls back to the bounded default when config has no value' do
      assistant = create(:captain_assistant)

      expect(assistant.max_turns).to eq(Captain::Assistant::DEFAULT_MAX_TURNS)
    end

    it 'reads the value from the assistant config' do
      assistant = create(:captain_assistant, config: { max_turns: 7 })

      expect(assistant.max_turns).to eq(7)
    end
  end
end
