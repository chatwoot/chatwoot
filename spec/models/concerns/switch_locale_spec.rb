require 'rails_helper'

RSpec.describe 'SwitchLocale Concern', type: :controller do
  controller(ApplicationController) do
    include SwitchLocale

    def index
      switch_locale { render plain: I18n.locale }
    end

    def account_locale
      switch_locale_using_account_locale { render plain: I18n.locale }
    end
  end

  let(:account) { create(:account, locale: 'es') }
  let(:portal) { create(:portal, custom_domain: 'custom.example.com', config: { default_locale: 'fr_FR' }) }

  describe '#switch_locale' do
    context 'when locale is provided in params' do
      it 'sets locale from params' do
        get :index, params: { locale: 'es' }
        expect(response.body).to eq('es')
      end

      it 'falls back to default locale if invalid' do
        get :index, params: { locale: 'invalid' }
        expect(response.body).to eq('en')
      end
    end

    context 'when user has a locale set in ui_settings' do
      let(:user) { create(:user, ui_settings: { 'locale' => 'es' }) }

      before { controller.instance_variable_set(:@user, user) }

      it 'returns the user locale' do
        expect(controller.send(:locale_from_user)).to eq('es')
      end
    end

    context 'when user does not have a locale set' do
      let(:user) { create(:user, ui_settings: {}) }

      before { controller.instance_variable_set(:@user, user) }

      it 'returns nil' do
        expect(controller.send(:locale_from_user)).to be_nil
      end
    end

    context 'when request is from custom domain' do
      before { request.host = portal.custom_domain }

      it 'sets locale from portal' do
        get :index
        expect(response.body).to eq('fr')
      end

      it 'overrides portal locale with param' do
        get :index, params: { locale: 'es' }
        expect(response.body).to eq('es')
      end
    end

    context 'when locale is not provided anywhere' do
      it 'sets locale from environment variable' do
        with_modified_env(DEFAULT_LOCALE: 'de_DE') do
          get :index
          expect(response.body).to eq('de')
        end
      end

      it 'falls back to default locale if env locale invalid' do
        with_modified_env(DEFAULT_LOCALE: 'invalid') do
          get :index
          expect(response.body).to eq('en')
        end
      end
    end
  end

  describe '#switch_locale_using_account_locale' do
    it 'sets locale from account' do
      controller.instance_variable_set(:@current_account, account)

      result = nil
      controller.send(:switch_locale_using_account_locale) do
        result = I18n.locale.to_s
      end

      expect(result).to eq('es')
    end
  end
end
