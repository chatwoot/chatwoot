# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Devise::Mailer' do
  describe 'notify' do
    let(:account) { create(:account) }
    let!(:confirmable_user) { create(:user, inviter: inviter_val, account: account) }
    let(:inviter_val) { nil }
    let(:mail) { Devise::Mailer.confirmation_instructions(confirmable_user.reload, nil, {}) }
    let(:mail_body) { CGI.unescapeHTML(mail.body.to_s) }

    before do
      # to verify the token in email
      confirmable_user.update!(confirmed_at: nil)
      confirmable_user.send(:generate_confirmation_token)
    end

    it 'has the correct header data' do
      expect(mail.reply_to).to contain_exactly('accounts@chatwoot.com')
      expect(mail.to).to contain_exactly(confirmable_user.email)
      expect(mail.subject).to eq('Confirmation Instructions')
    end

    it 'uses the user\'s name' do
      expect(mail.body.to_s).to include("Hi #{CGI.escapeHTML(confirmable_user.name)},")
      expect(mail_body).to include("Hi #{confirmable_user.name},")
    end

    context 'when the user name contains HTML' do
      before do
        confirmable_user.update!(name: 'Sony <script>alert(1)</script>')
      end

      it 'escapes the name in the rendered email body' do
        expect(mail.body.to_s).to include("Hi #{CGI.escapeHTML(confirmable_user.name)},")
        expect(mail.body.to_s).not_to include("Hi #{confirmable_user.name},")
      end
    end

    it 'shows the default confirmation state' do
      expect(mail_body).to include('Confirm your email to get started')
      expect(mail_body).to include('Welcome to Chatwoot. We just need to verify your email address before you can start using your account.')
      expect(mail_body).to include('Confirm my account')
      expect(mail_body).not_to include('Workspace invitation')
    end

    it 'sends a confirmation link' do
      expect(mail.body).to include("app/auth/confirmation?confirmation_token=#{confirmable_user.confirmation_token}")
      expect(mail.body).not_to include('app/auth/password/edit')
    end

    context 'when there is an inviter' do
      let(:inviter_val) { create(:user, :administrator, skip_confirmation: true, account: account) }

      it 'refers to the inviter and their account' do
        expect(mail_body).to include("You're invited to join #{account.name}")
        expect(mail_body).to include("#{inviter_val.name} invited you to join the #{account.name} workspace on Chatwoot.")
        expect(mail_body).to include('Accept invitation')
        expect(mail_body).not_to include('Confirm your email to get started')
      end

      it 'sends a password reset link' do
        expect(mail.body).to include('app/auth/password/edit?reset_password_token')
        expect(mail.body).not_to include('app/auth/confirmation')
      end
    end

    context 'when user updates the email' do
      before do
        confirmable_user.update!(email: 'user@example.com')
      end

      it 'sends a confirmation link' do
        confirmation_mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, nil, {})
        confirmation_body = CGI.unescapeHTML(confirmation_mail.body.to_s)

        expect(confirmation_body).to include('Confirm your new email address')
        expect(confirmation_body).to include('New email')
        expect(confirmation_mail.body).to include('app/auth/confirmation?confirmation_token')
        expect(confirmation_mail.body).not_to include('app/auth/password/edit')
        expect(confirmable_user.unconfirmed_email.blank?).to be false
      end
    end

    context 'when user is confirmed and updates the email' do
      before do
        confirmable_user.confirm
        confirmable_user.update!(email: 'user@example.com')
      end

      it 'sends a confirmation link' do
        confirmation_mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, nil, {})
        confirmation_body = CGI.unescapeHTML(confirmation_mail.body.to_s)

        expect(confirmation_body).to include('Confirm your new email address')
        expect(confirmation_mail.body).to include('app/auth/confirmation?confirmation_token')
        expect(confirmation_mail.body).not_to include('app/auth/password/edit')
        expect(confirmable_user.unconfirmed_email.blank?).to be false
      end
    end

    context 'when user already confirmed' do
      before do
        confirmable_user.confirm
        confirmable_user.account_users.last.destroy!
      end

      it 'send instructions with the link to login' do
        confirmation_mail = Devise::Mailer.confirmation_instructions(confirmable_user.reload, nil, {})
        confirmation_body = CGI.unescapeHTML(confirmation_mail.body.to_s)

        expect(confirmation_body).to include('Your account is ready')
        expect(confirmation_body).to include('Open my account')
        expect(confirmation_mail.body).to include('/auth/sign_in')
      end
    end
  end
end
