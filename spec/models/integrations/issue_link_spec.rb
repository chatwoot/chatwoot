require 'rails_helper'

RSpec.describe Integrations::IssueLink do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
  end

  describe 'validations' do
    subject { build(:integrations_issue_link) }

    it { is_expected.to validate_presence_of(:app_id) }
    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:external_url) }

    it 'validates external ID uniqueness within an account and app' do
      account = create(:account)
      conversation = create(:conversation, account: account)
      create(:integrations_issue_link, account: account, conversation: conversation, app_id: 'notion', external_id: 'issue-1')

      duplicate = build(:integrations_issue_link, account: account, conversation: conversation, app_id: 'notion', external_id: 'issue-1')
      different_app = build(:integrations_issue_link, account: account, conversation: conversation, app_id: 'linear', external_id: 'issue-1')
      different_account = build(:integrations_issue_link, app_id: 'notion', external_id: 'issue-1')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_id]).to include('has already been taken')
      expect(different_app).to be_valid
      expect(different_account).to be_valid
    end
  end
end
