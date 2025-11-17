# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationMailer do
  describe '#default_from_address' do
    context 'with custom BRAND_NAME' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'MAILER_SENDER_EMAIL', 'BRAND_URL').and_return({
          'BRAND_NAME' => 'Custom Support',
          'MAILER_SENDER_EMAIL' => nil,
          'BRAND_URL' => 'https://custom.example.com'
        })
      end

      it 'uses the custom brand name' do
        mailer = Class.new(ApplicationMailer)
        expect(mailer.new.send(:default_from_address)).to eq('Custom Support <accounts@custom.example.com>')
      end
    end

    context 'with MAILER_SENDER_EMAIL configured' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'MAILER_SENDER_EMAIL', 'BRAND_URL').and_return({
          'BRAND_NAME' => 'Custom Support',
          'MAILER_SENDER_EMAIL' => 'support@custom.com',
          'BRAND_URL' => 'https://custom.example.com'
        })
      end

      it 'uses the configured sender email' do
        mailer = Class.new(ApplicationMailer)
        expect(mailer.new.send(:default_from_address)).to eq('Custom Support <support@custom.com>')
      end
    end

    context 'with MAILER_SENDER_EMAIL with display name' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'MAILER_SENDER_EMAIL', 'BRAND_URL').and_return({
          'BRAND_NAME' => nil,
          'MAILER_SENDER_EMAIL' => 'Custom Support <support@custom.com>',
          'BRAND_URL' => 'https://custom.example.com'
        })
      end

      it 'uses the display name from MAILER_SENDER_EMAIL' do
        mailer = Class.new(ApplicationMailer)
        expect(mailer.new.send(:default_from_address)).to eq('Custom Support <support@custom.com>')
      end
    end

    context 'with default fallbacks' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'MAILER_SENDER_EMAIL', 'BRAND_URL').and_return({
          'BRAND_NAME' => nil,
          'MAILER_SENDER_EMAIL' => nil,
          'BRAND_URL' => nil
        })
      end

      it 'falls back to Chatwoot branding' do
        mailer = Class.new(ApplicationMailer)
        expect(mailer.new.send(:default_from_address)).to eq('Chatwoot <accounts@chatwoot.com>')
      end
    end
  end

  describe '#brand_name' do
    context 'with custom BRAND_NAME' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'INSTALLATION_NAME').and_return({
          'BRAND_NAME' => 'Custom Support',
          'INSTALLATION_NAME' => 'Installation Name'
        })
      end

      it 'returns the custom brand name' do
        mailer = Class.new(ApplicationMailer)
        expect(mailer.new.send(:brand_name)).to eq('Custom Support')
      end
    end

    context 'without BRAND_NAME but with INSTALLATION_NAME' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'INSTALLATION_NAME').and_return({
          'BRAND_NAME' => nil,
          'INSTALLATION_NAME' => 'Installation Name'
        })
      end

      it 'returns the installation name' do
        mailer = Class.new(ApplicationMailer)
        expect(mailer.new.send(:brand_name)).to eq('Installation Name')
      end
    end

    context 'with neither BRAND_NAME nor INSTALLATION_NAME' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'INSTALLATION_NAME').and_return({
          'BRAND_NAME' => nil,
          'INSTALLATION_NAME' => nil
        })
      end

      it 'returns Chatwoot as fallback' do
        mailer = Class.new(ApplicationMailer)
        expect(mailer.new.send(:brand_name)).to eq('Chatwoot')
      end
    end
  end

  describe '#brand_url' do
    context 'with custom BRAND_URL' do
      before do
        allow(GlobalConfig).to receive(:get_value).with('BRAND_URL').and_return('https://custom.example.com')
      end

      it 'returns the custom brand URL' do
        mailer = Class.new(ApplicationMailer)
        expect(mailer.new.send(:brand_url)).to eq('https://custom.example.com')
      end
    end

    context 'without BRAND_URL' do
      before do
        allow(GlobalConfig).to receive(:get_value).with('BRAND_URL').and_return(nil)
      end

      it 'returns the default Chatwoot URL' do
        mailer = Class.new(ApplicationMailer)
        expect(mailer.new.send(:brand_url)).to eq('https://www.chatwoot.com')
      end
    end
  end

  describe '#liquid_locals' do
    it 'includes brand_name and brand_url in liquid locals' do
      mailer = Class.new(ApplicationMailer)
      instance = mailer.new
      
      allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'BRAND_URL').and_return({
        'BRAND_NAME' => 'Custom Support',
        'BRAND_URL' => 'https://custom.example.com'
      })
      allow(instance).to receive(:brand_name).and_return('Custom Support')
      allow(instance).to receive(:brand_url).and_return('https://custom.example.com')
      
      locals = instance.send(:liquid_locals)
      
      expect(locals[:brand_name]).to eq('Custom Support')
      expect(locals[:brand_url]).to eq('https://custom.example.com')
    end
  end
end