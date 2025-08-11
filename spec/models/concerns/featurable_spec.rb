require 'rails_helper'

RSpec.describe Featurable do
  let(:account) { create(:account) }

  describe 'WhatsApp embedded signup feature' do
    it 'is disabled by default' do
      expect(account.feature_whatsapp_embedded_signup?).to be false
      expect(account.feature_enabled?('whatsapp_embedded_signup')).to be false
    end

    describe '#enable_features!' do
      it 'enables the whatsapp embedded signup feature' do
        account.enable_features!(:whatsapp_embedded_signup)
        expect(account.feature_whatsapp_embedded_signup?).to be true
        expect(account.feature_enabled?('whatsapp_embedded_signup')).to be true
      end

      it 'enables multiple features at once' do
        account.enable_features!(:whatsapp_embedded_signup, :help_center)
        expect(account.feature_whatsapp_embedded_signup?).to be true
        expect(account.feature_help_center?).to be true
      end
    end

    describe '#disable_features!' do
      before do
        account.enable_features!(:whatsapp_embedded_signup)
      end

      it 'disables the whatsapp embedded signup feature' do
        expect(account.feature_whatsapp_embedded_signup?).to be true

        account.disable_features!(:whatsapp_embedded_signup)
        expect(account.feature_whatsapp_embedded_signup?).to be false
      end
    end

    describe '#enabled_features' do
      it 'includes whatsapp_embedded_signup when enabled' do
        account.enable_features!(:whatsapp_embedded_signup)
        expect(account.enabled_features).to include('whatsapp_embedded_signup' => true)
      end

      it 'does not include whatsapp_embedded_signup when disabled' do
        account.disable_features!(:whatsapp_embedded_signup)
        expect(account.enabled_features).not_to include('whatsapp_embedded_signup' => true)
      end
    end

    describe '#all_features' do
      it 'includes whatsapp_embedded_signup in all features list' do
        expect(account.all_features).to have_key('whatsapp_embedded_signup')
      end
    end
  end
end
