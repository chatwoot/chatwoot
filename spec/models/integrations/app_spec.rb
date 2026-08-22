require 'rails_helper'

RSpec.describe Integrations::App do
  let(:apps) { described_class }
  let(:app) { apps.find(id: app_name) }
  let(:account) { create(:account) }

  describe '#name' do
    let(:app_name) { 'dialogflow' }

    it 'returns the name' do
      expect(app.name).to eq('Dialogflow')
    end
  end

  describe '#logo' do
    let(:app_name) { 'dialogflow' }

    it 'returns the logo' do
      expect(app.logo).to eq('dialogflow.png')
    end
  end

  describe '#visible_properties' do
    context 'when the app has visible properties' do
      let(:app_name) { 'dialogflow' }

      it 'returns the configured property names as strings' do
        expect(app.visible_properties).to contain_exactly('project_id', 'region', 'language_code')
      end
    end

    context 'when the app has no visible properties configured' do
      let(:app_name) { 'webhook' }

      it 'defaults to an empty list' do
        expect(app.visible_properties).to eq([])
      end
    end
  end

  describe '#active?' do
    context 'when other apps are queried' do
      let(:app_name) { 'webhook' }

      it 'returns true' do
        expect(app.active?(account)).to be true
      end
    end
  end

  describe '#enabled?' do
    context 'when the app is webhook' do
      let(:app_name) { 'webhook' }

      it 'returns false if the account does not have any webhooks' do
        expect(app.enabled?(account)).to be false
      end

      it 'returns true if the account has webhooks' do
        create(:webhook, account: account)
        expect(app.enabled?(account)).to be true
      end
    end

    context 'when the app is anything other than webhook' do
      let(:app_name) { 'dialogflow' }

      it 'returns false if the account does not have any hooks for the app' do
        expect(app.enabled?(account)).to be false
      end

      it 'returns true if the account has hooks for the app' do
        create(:integrations_hook, :dialogflow, account: account)
        expect(app.enabled?(account)).to be true
      end
    end
  end
end
