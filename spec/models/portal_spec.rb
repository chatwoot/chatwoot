require 'rails_helper'

RSpec.describe Portal do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:categories) }
    it { is_expected.to have_many(:folders) }
    it { is_expected.to have_many(:articles) }
    it { is_expected.to have_many(:inboxes) }
  end

  describe 'validations' do
    let!(:account) { create(:account) }
    let!(:portal) { create(:portal, account_id: account.id) }

    context 'when set portal config' do
      it 'Adds default allowed_locales en' do
        expect(portal.config).to be_present
        expect(portal.config['allowed_locales']).to eq(['en'])
        expect(portal.config['default_locale']).to eq('en')
        expect(portal.config['draft_locales']).to eq([])
      end

      it 'Does not allow any other config than allowed_locales' do
        portal.update(config: { 'some_other_key': 'test_value' })
        expect(portal).not_to be_valid
        expect(portal.errors.full_messages[0]).to eq('Cofig in portal on some_other_key is not supported.')
      end

      it 'falls back to no drafted locales for existing portals' do
        portal.config = { 'allowed_locales' => %w[en es], 'default_locale' => 'en' }

        expect(portal.draft_locale_codes).to eq([])
        expect(portal.public_locale_codes).to eq(%w[en es])
      end

      it 'preserves drafted locales when draft_locales is omitted on update' do
        portal.update!(config: { allowed_locales: %w[en es fr], draft_locales: ['es'], default_locale: 'en' })

        portal.assign_attributes(config: { allowed_locales: %w[en es fr], default_locale: 'en' })
        portal.valid?

        expect(portal.config['draft_locales']).to eq(['es'])
      end

      it 'does not allow drafting the default locale' do
        portal.update(config: { allowed_locales: %w[en es], draft_locales: ['en'], default_locale: 'en' })

        expect(portal).not_to be_valid
        expect(portal.errors.full_messages).to include('Config default locale cannot be drafted.')
      end

      it 'converts empty string to nil' do
        portal.update(custom_domain: '')
        expect(portal.custom_domain).to be_nil
      end
    end
  end
end
