require 'rails_helper'

RSpec.describe Captain::Copilot::UnsourcedNumbers do
  describe '.numbers_in' do
    it 'reads a comma or a dot as the decimal mark or as a thousands separator' do
      expect(described_class.numbers_in('23,5% of 1.234 chats, 2,000 contacts and 1.234,5 points')).to eq(
        '23,5%' => ['23.5%'], '1.234' => %w[1234 1.234], '2,000' => ['2000'], '1.234,5' => ['1234.5']
      )
    end

    it 'skips dates, years and numbers no convention reads' do
      expect(described_class.numbers_in('Since 2026-07-17 in 2026, version 3.5.2 had 5')).to eq('5' => ['5'])
    end
  end

  describe '#note_for' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }
    let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
    let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
    let(:turn) { CopilotRun.create!(account: account, user: user, copilot_thread: thread, copilot_message: message, kind: :turn) }
    let(:token) { turn.claim }

    before do
      turn.tool_calls.create!(call_id: 'call-1', name: 'get_data', status: :completed,
                              result: { total: 1234, groups: [{ count: 2 }], share: '23.5%' })
    end

    it 'lists only the numbers no tool returned, as the answer wrote them' do
      described_class.new(turn, token).note_for('Es gab 1.234 Gespräche, davon 23,5% offen, 2,000 gelöst und 7 neu.')

      expect(turn.reload.context['unsourced_numbers_in_draft']).to eq(%w[7 2,000])
    end
  end
end
