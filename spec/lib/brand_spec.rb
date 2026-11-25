# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Brand do
  let(:account) { create(:account) }

  def install(values)
    values.each { |name, value| InstallationConfig.where(name: name).first_or_initialize.update!(value: value) }
    GlobalConfig.clear_cache
  end

  before do
    install(
      'BRAND_NAME' => 'Chatwoot',
      'BRAND_URL' => 'https://www.chatwoot.com',
      'BRAND_COLOR' => '#1F93FF',
      'LOGO' => '/brand-assets/logo.svg',
      'LOGO_EMAIL' => ''
    )
  end

  context 'without an account' do
    it 'is the installation brand' do
      brand = described_class.for

      expect(brand.name).to eq 'Chatwoot'
      expect(brand.url).to eq 'https://www.chatwoot.com'
      expect(brand.color).to eq '#1F93FF'
    end
  end

  context 'when the account has not enabled branded email templates' do
    before { account.update!(brand_name: 'Café Exemplo', brand_color: '#11D135') }

    it 'ignores what the account configured' do
      brand = described_class.for(account: account)

      expect(brand.name).to eq 'Chatwoot'
      expect(brand.color).to eq '#1F93FF'
    end
  end

  context 'when the account has enabled branded email templates' do
    before { account.enable_features!('branded_email_templates') }

    it 'overrides field by field, leaving the rest on the installation' do
      account.update!(brand_color: '#11D135')

      brand = described_class.for(account: account)

      expect(brand.color).to eq '#11D135'
      expect(brand.name).to eq 'Chatwoot'
      expect(brand.url).to eq 'https://www.chatwoot.com'
    end

    # The settings form posts empty strings, so an administrator who opens the screen and saves
    # it untouched would otherwise strip the brand from every email the account sends.
    it 'falls back on a field the account left empty' do
      account.update!(brand_name: '')

      expect(described_class.for(account: account).name).to eq 'Chatwoot'
    end

    it 'keys the config like the installation, so a stored layout keeps resolving' do
      account.update!(brand_name: 'Café Exemplo')

      config = described_class.for(account: account).config

      expect(config['BRAND_NAME']).to eq 'Café Exemplo'
      expect(config['LOGO']).to eq '/brand-assets/logo.svg'
    end
  end

  describe '#logo_url' do
    it 'falls back to LOGO when it is a format email can render' do
      install('LOGO' => '/brand-assets/logo.png')

      with_modified_env 'FRONTEND_URL' => 'https://atendimento.example.com' do
        expect(described_class.for.logo_url).to eq 'https://atendimento.example.com/brand-assets/logo.png'
      end
    end

    it 'shows no logo rather than a broken one when LOGO is an SVG' do
      expect(described_class.for.logo_url).to eq ''
    end

    it 'leaves an absolute LOGO_EMAIL alone' do
      install('LOGO_EMAIL' => 'https://cdn.example.com/logo.png')

      expect(described_class.for.logo_url).to eq 'https://cdn.example.com/logo.png'
    end

    context 'with a logo attached to the account' do
      before do
        account.enable_features!('branded_email_templates')
        account.brand_logo_email.attach(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )
      end

      it 'serves it from this installation, so the URL does not expire like a signed one' do
        url = described_class.for(account: account).logo_url

        expect(url).to start_with 'http://localhost:3000/rails/active_storage/blobs/redirect/'
      end

      it 'ignores it when the feature is off' do
        account.disable_features!('branded_email_templates')

        expect(described_class.for(account: account).logo_url).to eq ''
      end
    end
  end

  describe '#web_config' do
    before do
      install(
        'LOGO_THUMBNAIL' => '/brand-assets/logo_thumbnail.svg',
        'WIDGET_BRAND_URL' => 'https://www.chatwoot.com'
      )
    end

    context 'without an account' do
      it 'is the installation brand' do
        config = described_class.for.web_config

        expect(config['BRAND_NAME']).to eq 'Chatwoot'
        expect(config['WIDGET_BRAND_URL']).to eq 'https://www.chatwoot.com'
        expect(config['LOGO_THUMBNAIL']).to eq '/brand-assets/logo_thumbnail.svg'
      end

      it 'leaves the hero logo empty rather than lending the installation mark to a page' do
        expect(described_class.for.web_config['BRAND_LOGO_URL']).to eq ''
      end
    end

    context 'when the account configured a brand' do
      before do
        account.enable_features!('branded_email_templates')
        account.update!(
          brand_name: 'Bistrô Exemplo',
          brand_url: 'https://www.bistro-exemplo.com.br',
          brand_color: '#F82323'
        )
      end

      it 'wears the brand of the account' do
        config = described_class.for(account: account).web_config

        expect(config['BRAND_NAME']).to eq 'Bistrô Exemplo'
        expect(config['WIDGET_BRAND_URL']).to eq 'https://www.bistro-exemplo.com.br'
      end

      it 'falls back field by field to the installation' do
        account.update!(brand_url: '')

        config = described_class.for(account: account).web_config

        expect(config['BRAND_NAME']).to eq 'Bistrô Exemplo'
        expect(config['WIDGET_BRAND_URL']).to eq 'https://www.chatwoot.com'
      end

      it 'ignores the account when the feature is off' do
        account.disable_features!('branded_email_templates')

        expect(described_class.for(account: account).web_config['BRAND_NAME']).to eq 'Chatwoot'
      end

      # The page renders a different footer for each, so a name that merely fell back must not
      # look like one the account chose.
      it 'says the name came from the account' do
        expect(described_class.for(account: account).web_config['BRAND_FROM_ACCOUNT']).to be true
      end

      it 'says it did not when the account named nothing' do
        account.update!(brand_name: '')

        expect(described_class.for(account: account).web_config['BRAND_FROM_ACCOUNT']).to be false
      end

      it 'gives white text on the strong colour a legible background' do
        config = described_class.for(account: account).web_config

        expect(config['BRAND_COLOR']).to eq BrandColor.surface('#F82323')
        expect(config['BRAND_COLOR_STRONG']).to eq BrandColor.on_light('#F82323')
      end

      context 'with a logo attached' do
        before do
          account.brand_logo_email.attach(
            io: Rails.root.join('spec/assets/avatar.png').open,
            filename: 'avatar.png',
            content_type: 'image/png'
          )
        end

        it 'uses it for both the footer thumbnail and the hero' do
          config = described_class.for(account: account).web_config

          expect(config['LOGO_THUMBNAIL']).to start_with 'http://localhost:3000/rails/active_storage/blobs/redirect/'
          expect(config['BRAND_LOGO_URL']).to eq config['LOGO_THUMBNAIL']
        end
      end

      it 'keeps the installation thumbnail when the account attached no logo' do
        config = described_class.for(account: account).web_config

        expect(config['LOGO_THUMBNAIL']).to eq '/brand-assets/logo_thumbnail.svg'
        expect(config['BRAND_LOGO_URL']).to eq ''
      end
    end

    # The mail layouts customers already stored read #config as `global_config`. Widening it
    # would quietly change what those layouts see, which is why the web keys live apart.
    it 'does not widen the hash the stored mail layouts read' do
      expect(described_class.for.config.keys).to match_array(described_class::INSTALLATION_KEYS)
    end
  end
end
