require 'rails_helper'

RSpec.describe AdministratorNotifications::BaseMailer do
  let!(:account) { create(:account) }
  let!(:admin1) { create(:user, account: account, role: :administrator) }
  let!(:admin2) { create(:user, account: account, role: :administrator) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let(:mailer) { described_class.new }
  let!(:inbox) { create(:inbox, account: account) }

  before do
    Current.account = account
  end

  describe 'admin_emails' do
    it 'returns emails of all administrators' do
      # Call the private method
      admin_emails = mailer.send(:admin_emails)

      expect(admin_emails).to include(admin1.email)
      expect(admin_emails).to include(admin2.email)
      expect(admin_emails).not_to include(agent.email)
    end
  end

  describe 'helper methods' do
    it 'generates correct inbox URL' do
      url = mailer.inbox_url(inbox)
      expected_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/inboxes/#{inbox.id}"
      expect(url).to eq(expected_url)
    end

    it 'generates correct settings URL' do
      url = mailer.settings_url('automation/list')
      expected_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/automation/list"
      expect(url).to eq(expected_url)
    end
  end

  describe 'send_notification' do
    before do
      allow(mailer).to receive(:smtp_config_set_or_development?).and_return(true)
    end

    it 'sends email with correct parameters' do
      subject = 'Test Subject'
      action_url = 'https://example.com'
      meta = { 'key' => 'value' }

      # Mock the send_mail_with_liquid method
      expect(mailer).to receive(:send_mail_with_liquid).with(
        to: [admin1.email, admin2.email],
        subject: subject
      ).and_return(true)

      mailer.send_notification(subject, action_url: action_url, meta: meta)

      # Check that instance variables are set correctly
      expect(mailer.instance_variable_get(:@action_url)).to eq(action_url)
      expect(mailer.instance_variable_get(:@meta)).to eq(meta)
    end

    it 'uses provided email addresses when specified' do
      subject = 'Test Subject'
      custom_email = 'custom@example.com'

      expect(mailer).to receive(:send_mail_with_liquid).with(
        to: custom_email,
        subject: subject
      ).and_return(true)

      mailer.send_notification(subject, to: custom_email)
    end
  end
end
