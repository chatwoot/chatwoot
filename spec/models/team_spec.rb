require 'rails_helper'

RSpec.describe Team do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:conversations) }
    it { is_expected.to have_many(:team_members) }
  end

  describe 'name normalization' do
    let(:account) { create(:account) }

    it 'downcases the name' do
      team = create(:team, account: account, name: 'Customer Support')
      expect(team.name).to eq('customer support')
    end

    it 'strips control characters and surrounding whitespace' do
      team = create(:team, account: account, name: "  Sales\n")
      expect(team.name).to eq('sales')
    end

    it 'removes control characters embedded within the name' do
      team = create(:team, account: account, name: "su\npport")
      expect(team.name).to eq('support')
    end

    it 'is invalid when the name reduces to blank after sanitization' do
      team = build(:team, account: account, name: "\t\n  ")
      expect(team).not_to be_valid
      expect(team.errors[:name]).to include(I18n.t('errors.validations.presence'))
    end
  end

  describe '#add_members' do
    let(:team) { FactoryBot.create(:team) }

    before do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
    end

    it 'handles adds all members and resets cache keys' do
      users = FactoryBot.create_list(:user, 3)
      team.add_members(users.map(&:id))
      expect(team.reload.team_members.size).to eq(3)

      expect(Rails.configuration.dispatcher).to have_received(:dispatch).at_least(:once)
                                                                        .with(
                                                                          'account.cache_invalidated',
                                                                          kind_of(Time),
                                                                          account: team.account,
                                                                          cache_keys: team.account.cache_keys
                                                                        )
    end
  end

  describe '#remove_members' do
    let(:team) { FactoryBot.create(:team) }
    let(:users) { FactoryBot.create_list(:user, 3) }

    before do
      team.add_members(users.map(&:id))
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
    end

    it 'removes the members and resets cache keys' do
      expect(team.reload.team_members.size).to eq(3)

      team.remove_members(users.map(&:id))
      expect(team.reload.team_members.size).to eq(0)

      expect(Rails.configuration.dispatcher).to have_received(:dispatch).at_least(:once)
                                                                        .with(
                                                                          'account.cache_invalidated',
                                                                          kind_of(Time),
                                                                          account: team.account,
                                                                          cache_keys: team.account.cache_keys
                                                                        )
    end
  end
end
