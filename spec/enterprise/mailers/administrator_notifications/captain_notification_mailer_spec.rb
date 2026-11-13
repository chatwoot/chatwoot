require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

RSpec.describe AdministratorNotifications::CaptainNotificationMailer do
  include_context 'with smtp config'

  let(:account) { create(:account, name: 'Acme Inc') }
  let!(:administrator) { create(:user, :administrator, email: 'admin@example.com', account: account) }
  let!(:another_administrator) { create(:user, :administrator, email: 'owner@example.com', account: account) }
  let!(:agent) { create(:user, email: 'agent@example.com', account: account, role: :agent) }

  it 'renders the credit balance and Billing link for every administrator' do
    with_modified_env('FRONTEND_URL' => 'https://app.chatwoot.com') do
      mail = described_class.with(account: account).response_usage_alert(consumed: 241, remaining: 59)

      expect(mail.subject).to eq(I18n.t('administrator_notifications.captain.response_usage_alert.subject'))
      expect(mail.to).to contain_exactly(administrator.email, another_administrator.email)
      expect(mail.to).not_to include(agent.email)
      expect(mail.body.encoded).to include('Acme Inc')
      expect(mail.body.encoded).to include('241 credits have been used, and 59 credits remain')
      expect(mail.body.encoded).to include("https://app.chatwoot.com/app/accounts/#{account.id}/settings/billing")
    end
  end
end
