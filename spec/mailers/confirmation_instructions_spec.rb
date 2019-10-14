# frozen_string_literal: true

require 'rails_helper' 

RSpec.describe 'Confirmation Instructions', type: :mailer do
  describe :notify do
    let!(:admin_user) do
      FactoryBot.create(:user, role: :administrator, skip_confirmation: true)
    end
    let(:confirmable_user) { FactoryBot.build(:user, inviter: admin_user) }

    let(:mail) { confirmable_user.send_confirmation_instructions }

    it 'has the correct header data' do
      expect(mail.reply_to).to contain_exactly('accounts@chatwoot.com')
      expect(mail.to).to contain_exactly(confirmable_user.email)
      expect(mail.subject).to eq('Confirmation Instructions')
    end

    it 'uses the user\'s name' do
      expect(mail.body).to match("Welcome, #{confirmable_user.name}!")
    end

    it 'refers to the inviter and their account' do
      expect(mail.body).to match(
        "#{admin_user.name}, with #{admin_user.account.name}, has invited you to try out Chatwoot!"
      )
    end
  end
end
