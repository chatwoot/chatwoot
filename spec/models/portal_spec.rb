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
        expect(portal.errors.full_messages[0]).to eq('Config in portal on some_other_key is not supported.')
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

      context 'with locale_translations' do
        it 'allows valid locale translations' do
          portal.update(config: { allowed_locales: %w[en es], default_locale: 'en',
                                  locale_translations: { 'es' => { 'name' => 'Centro', 'page_title' => 'Título', 'header_text' => 'Hola' } } })

          expect(portal).to be_valid
        end

        it 'rejects unknown fields within a locale translation' do
          portal.update(config: { allowed_locales: %w[en es], default_locale: 'en',
                                  locale_translations: { 'es' => { 'tagline' => 'nope' } } })

          expect(portal).not_to be_valid
        end

        it 'retains a locale override after it becomes the default so it can still be edited' do
          portal.update!(config: { allowed_locales: %w[en es], default_locale: 'en',
                                   locale_translations: { 'es' => { 'name' => 'Centro' } } })

          portal.update!(config: { allowed_locales: %w[en es], default_locale: 'es' })

          expect(portal.config['locale_translations']).to eq({ 'es' => { 'name' => 'Centro' } })
        end
      end
    end
  end

  describe '#widget_data' do
    it 'exposes only the slug and allowed locales' do
      portal = create(:portal, slug: 'docs', custom_domain: 'docs.example.com', config: { allowed_locales: %w[en es] })

      expect(portal.widget_data).to eq(slug: 'docs', config: { allowed_locales: %w[en es] })
    end
  end

  describe 'password protection' do
    let(:portal) { create(:portal) }

    it 'is public by default' do
      expect(portal.visibility).to eq('public')
      expect(portal.password_protected?).to be(false)
    end

    it 'requires a password to become password protected' do
      portal.update(config: { visibility: 'private_with_password' })

      expect(portal.errors[:password]).to include("can't be blank")
    end

    it 'rejects an unsupported visibility' do
      portal.update(config: { visibility: 'secret' })

      expect(portal).not_to be_valid
    end

    it 'cannot be password protected while linked to an inbox' do
      create(:inbox, account: portal.account, portal: portal)

      portal.update(config: { visibility: 'private_with_password' }, password: 'opensesame1')

      expect(portal.errors[:base]).to include('Remove this help center from its inboxes before password protecting it')
    end

    context 'when password protected' do
      before { portal.update!(config: { visibility: 'private_with_password' }, password: 'opensesame1') }

      it 'authenticates the password' do
        expect(portal.password_protected?).to be(true)
        expect(portal.authenticate('opensesame1')).to eq(portal)
        expect(portal.authenticate('wrong-password')).to be(false)
      end

      it 'keeps the password when other settings change' do
        portal.reload.update!(name: 'Renamed', config: { layout: 'documentation' })

        expect(portal.reload.password_protected?).to be(true)
        expect(portal.authenticate('opensesame1')).to eq(portal)
      end

      it 'removes the password when made public' do
        portal.update!(config: { visibility: 'public' })

        expect(portal.reload.password_digest).to be_nil
      end

      it 'leaves the password digest out of the serialized portal' do
        expect(portal.as_json.keys).not_to include('password_digest')
        expect(portal.to_json).not_to include(portal.password_digest)
      end
    end
  end

  describe '#localized_value' do
    let!(:account) { create(:account) }
    let!(:portal) do
      create(:portal, account_id: account.id, name: 'Help Center', page_title: 'Help Center | Acme',
                      config: { allowed_locales: %w[en es], default_locale: 'en',
                                locale_translations: { 'es' => { 'name' => 'Centro de ayuda' } } })
    end

    it 'returns the override for the requested locale' do
      expect(portal.localized_value('name', 'es')).to eq('Centro de ayuda')
    end

    it 'falls back to the base column when the locale has no override for the field' do
      expect(portal.localized_value('page_title', 'es')).to eq('Help Center | Acme')
    end

    it 'falls back to the base column when the locale has no overrides at all' do
      expect(portal.localized_value('name', 'fr')).to eq('Help Center')
    end

    it 'keeps serving the override for a locale that has become the default' do
      portal.update!(config: { allowed_locales: %w[en es], default_locale: 'es' })

      expect(portal.localized_value('name', 'es')).to eq('Centro de ayuda')
    end

    it "inherits the default locale's override for a locale without its own" do
      portal.update!(config: { allowed_locales: %w[en es fr], default_locale: 'es' })

      expect(portal.localized_value('name', 'fr')).to eq('Centro de ayuda')
    end

    it 'uses the default locale when no locale is given' do
      expect(portal.localized_value('name')).to eq('Help Center')
    end
  end

  describe '#display_title' do
    let!(:account) { create(:account) }

    it 'prefers the localized page_title' do
      portal = create(:portal, account_id: account.id, name: 'Help Center', page_title: 'Help Center | Acme',
                               config: { allowed_locales: %w[en es], default_locale: 'en',
                                         locale_translations: { 'es' => { 'page_title' => 'Centro | Acme' } } })

      expect(portal.display_title('es')).to eq('Centro | Acme')
    end

    it 'falls back to the localized name when no page_title is set' do
      portal = create(:portal, account_id: account.id, name: 'Help Center',
                               config: { allowed_locales: %w[en es], default_locale: 'en',
                                         locale_translations: { 'es' => { 'name' => 'Centro de ayuda' } } })

      expect(portal.display_title('es')).to eq('Centro de ayuda')
    end

    it 'uses the base values for the default locale' do
      portal = create(:portal, account_id: account.id, name: 'Help Center', page_title: 'Help Center | Acme')

      expect(portal.display_title).to eq('Help Center | Acme')
    end
  end
end
