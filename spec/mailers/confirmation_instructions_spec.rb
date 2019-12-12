# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Confirmation Instructions', type: :mailer do
  describe :notify do
    let(:confirmable_user) { FactoryBot.build(:user, inviter: inviter_val) }
    let(:inviter_val) { nil }
    let(:mail) { confirmable_user.send_confirmation_instructions }

    it 'has the correct header data' do
      expect(mail.reply_to).to contain_exactly('accounts@chatwoot.com')
      expect(mail.to).to contain_exactly(confirmable_user.email)
      expect(mail.subject).to eq('Confirmation Instructions')
    end

    it 'uses the user\'s name' do
      expect(mail.body).to match("Welcome, #{CGI.escapeHTML(confirmable_user.name)}!")
    end

    it 'does not refer to the inviter and their account' do
      expect(mail.body).to_not match('has invited you to try out Chatwoot!')
    end

    context 'when there is an inviter' do
      let(:inviter_val) do
        FactoryBot.create(:user, role: :administrator, skip_confirmation: true)
      end

      it 'refers to the inviter and their account' do
        expect(mail.body).to match(
          "#{inviter_val.name}, with #{inviter_val.account.name}, has invited you to try out Chatwoot!"
        )
      end
    end
  end
end
