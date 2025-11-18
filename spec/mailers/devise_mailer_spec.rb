# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Devise::Mailer' do
  describe 'confirmation_instructions' do
    let(:account) { create(:account) }
    let!(:confirmable_user) { create(:user, inviter: inviter_val, account: account) }
    let(:inviter_val) { nil }
    let(:mail) { Devise::Mailer.confirmation_instructions(confirmable_user.reload, nil, {}) }

    before do
      confirmable_user.update!(confirmed_at: nil)
      confirmable_user.send(:generate_confirmation_token)
    end

    context 'with custom brand name' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'INSTALLATION_NAME').and_return({
          'BRAND_NAME' => 'Custom Support',
          'INSTALLATION_NAME' => 'Installation Name'
        })
      end

      it 'uses custom brand name in welcome message' do
        expect(mail.body).to match('Welcome to Custom Support')
        expect(mail.body).not_to match('Welcome to Chatwoot')
      end

      it 'uses custom brand name in login message' do
        confirmable_user.confirm
        new_mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, nil, {})
        expect(new_mail.body).to match('login to your Custom Support account')
        expect(new_mail.body).not_to match('login to your Chatwoot account')
      end

      context 'when user has inviter' do
        let(:inviter_val) { create(:user, :administrator, skip_confirmation: true, account: account) }

        it 'uses custom brand name in invitation message' do
          expect(mail.body).to match('has invited you to try out Custom Support')
          expect(mail.body).not_to match('has invited you to try out Chatwoot')
        end
      end
    end

    context 'without custom brand name but with installation name' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'INSTALLATION_NAME').and_return({
          'BRAND_NAME' => nil,
          'INSTALLATION_NAME' => 'Installation Name'
        })
      end

      it 'uses installation name in welcome message' do
        expect(mail.body).to match('Welcome to Installation Name')
        expect(mail.body).not_to match('Welcome to Chatwoot')
      end
    end

    context 'with default fallback' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'INSTALLATION_NAME').and_return({
          'BRAND_NAME' => nil,
          'INSTALLATION_NAME' => nil
        })
      end

      it 'uses Chatwoot as fallback' do
        expect(mail.body).to match('Welcome to Chatwoot')
      end
    end
  end

  describe 'reset_password_instructions' do
    let(:user) { create(:user) }
    let(:mail) { Devise::Mailer.reset_password_instructions(user, 'token') }

    it 'sends password reset instructions without brand references' do
      expect(mail.body).to match('Someone has requested a link to change your password')
      expect(mail.body).to match('Change my password')
    end
  end

  describe 'from address' do
    let(:user) { create(:user) }
    let(:mail) { Devise::Mailer.confirmation_instructions(user, 'token') }

    context 'with custom branding' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'MAILER_SENDER_EMAIL', 'BRAND_URL').and_return({
          'BRAND_NAME' => 'Custom Support',
          'MAILER_SENDER_EMAIL' => 'support@custom.com',
          'BRAND_URL' => 'https://custom.example.com'
        })
      end

      it 'uses custom brand name in from address' do
        expect(mail.from).to include('support@custom.com')
      end

      it 'uses custom display name in from address' do
        # Note: ActionMailer's from field parsing is complex, we mainly test the email address
        expect(mail.header['from'].to_s).to include('Custom Support')
      end
    end

    context 'with default branding' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'MAILER_SENDER_EMAIL', 'BRAND_URL').and_return({
          'BRAND_NAME' => nil,
          'MAILER_SENDER_EMAIL' => nil,
          'BRAND_URL' => nil
        })
      end

      it 'uses default Chatwoot branding' do
        expect(mail.from).to include('accounts@chatwoot.com')
      end
    end
  end
end