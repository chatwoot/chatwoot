require 'rails_helper'

RSpec.describe Workflow::AccountTemplate, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:template_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe '#add_inbox' do
    let(:inbox) { FactoryBot.create(:inbox) }
    let(:account_template) { FactoryBot.create(:workflow_account_template) }

    it do
      expect(account_template.account_inbox_templates.size).to eq(0)

      account_template.add_inbox(inbox.id)
      expect(account_template.reload.account_inbox_templates.size).to eq(1)
    end
  end

  describe '#remove_inbox' do
    let(:inbox) { FactoryBot.create(:inbox) }
    let(:account_template) { FactoryBot.create(:workflow_account_template) }

    before { account_template.add_inbox(inbox.id) }

    it do
      expect(account_template.account_inbox_templates.size).to eq(1)

      account_template.remove_inbox(inbox.id)
      expect(account_template.reload.account_inbox_templates.size).to eq(0)
    end
  end
end
