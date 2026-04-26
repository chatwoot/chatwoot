require 'rails_helper'

RSpec.describe Synapseos::AgenticMirrored do
  let(:account) { create(:account) }
  let(:bot) { AgentBot.create!(account_id: account.id, name: 'Otto', squadron_role: 'otto', description: description) }

  describe '#mark_synapseos_disabled! / #synapseos_disabled?' do
    context 'when description is nil' do
      let(:description) { nil }

      it 'marks the bot as disabled and synapseos_disabled? returns true' do
        bot.mark_synapseos_disabled!
        expect(bot.reload.synapseos_disabled?).to be true
        expect(bot.description).to eq('[DISABLED]')
      end
    end

    context 'when description is blank' do
      let(:description) { '' }

      it 'marks the bot as disabled and synapseos_disabled? returns true' do
        bot.mark_synapseos_disabled!
        expect(bot.reload.synapseos_disabled?).to be true
      end
    end

    context 'when description is present' do
      let(:description) { 'Synapse OS — Otto' }

      it 'prepends the disabled prefix preserving the original description' do
        bot.mark_synapseos_disabled!
        expect(bot.reload.description).to eq('[DISABLED] Synapse OS — Otto')
        expect(bot.synapseos_disabled?).to be true
      end

      it 'is idempotent — calling twice does not double the prefix' do
        bot.mark_synapseos_disabled!
        first = bot.reload.description
        bot.mark_synapseos_disabled!
        expect(bot.reload.description).to eq(first)
      end
    end
  end

  describe '#mark_synapseos_enabled!' do
    context 'when previously disabled with no original description' do
      let(:description) { nil }

      it 'clears the prefix and leaves description nil' do
        bot.mark_synapseos_disabled!
        expect(bot.reload.synapseos_disabled?).to be true

        bot.mark_synapseos_enabled!
        expect(bot.reload.synapseos_disabled?).to be false
        expect(bot.description).to be_nil
      end
    end

    context 'when previously disabled with an original description' do
      let(:description) { 'Synapse OS — Otto' }

      it 'restores the original description' do
        bot.mark_synapseos_disabled!
        bot.mark_synapseos_enabled!
        expect(bot.reload.description).to eq('Synapse OS — Otto')
        expect(bot.synapseos_disabled?).to be false
      end
    end
  end
end
