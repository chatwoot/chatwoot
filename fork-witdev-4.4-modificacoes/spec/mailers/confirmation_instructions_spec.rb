# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Devise::Mailer' do
  describe 'notify' do
    let(:account) { create(:account) }
    let!(:confirmable_user) { create(:user, inviter: inviter_val, account: account) }
    let(:inviter_val) { nil }
    let(:mail) { Devise::Mailer.confirmation_instructions(confirmable_user.reload, nil, {}) }

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
      expect(mail.body).to match("Hi #{CGI.escapeHTML(confirmable_user.name)},")
    end

    it 'does not refer to the inviter and their account' do
      expect(mail.body).not_to match('has invited you to try out Chatwoot!')
      expect(mail.body).to match('We have a suite of powerful tools ready for you to explore.')
    end

    it 'sends a confirmation link' do
      expect(mail.body).to include("app/auth/confirmation?confirmation_token=#{confirmable_user.confirmation_token}")
      expect(mail.body).not_to include('app/auth/password/edit')
    end

    context 'when there is an inviter' do
      let(:inviter_val) { create(:user, :administrator, skip_confirmation: true, account: account) }

      it 'refers to the inviter and their account' do
        expect(mail.body).to match(
          "#{CGI.escapeHTML(inviter_val.name)}, with #{CGI.escapeHTML(account.name)}, has invited you to try out Chatwoot."
        )
        expect(mail.body).not_to match('We have a suite of powerful tools ready for you to explore.')
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
        expect(confirmation_mail.body).to include('/auth/sign_in')
      end
    end
  end
end
