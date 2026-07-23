require 'rails_helper'

RSpec.describe EmailTemplate do
  describe 'validations' do
    it 'allows the same layout name across installation, account, and inbox scopes' do
      account = create(:account)
      inbox = create(:inbox, :with_email, account: account)

      create(:email_template, :layout, account: nil)
      create(:email_template, :layout, account: account)
      inbox_template = build(:email_template, :layout, account: account, inbox: inbox)

      expect(inbox_template).to be_valid
    end

    it 'allows an account-scoped layout after an inbox-scoped layout' do
      account = create(:account)
      inbox = create(:inbox, :with_email, account: account)
      create(:email_template, :layout, account: account, inbox: inbox)

      account_template = build(:email_template, :layout, account: account)

      expect(account_template).to be_valid
    end

    it 'allows an installation-scoped layout after account and inbox-scoped layouts' do
      account = create(:account)
      inbox = create(:inbox, :with_email, account: account)
      create(:email_template, :layout, account: account)
      create(:email_template, :layout, account: account, inbox: inbox)

      installation_template = build(:email_template, :layout, account: nil)

      expect(installation_template).to be_valid
    end

    it 'rejects duplicate installation-scoped templates' do
      create(:email_template)
      duplicate_template = build(:email_template)

      expect(duplicate_template).not_to be_valid
      expect(duplicate_template.errors[:name]).to include('has already been taken')
    end

    it 'rejects duplicate account-scoped templates' do
      account = create(:account)
      create(:email_template, account: account)
      duplicate_template = build(:email_template, account: account)

      expect(duplicate_template).not_to be_valid
      expect(duplicate_template.errors[:name]).to include('has already been taken')
    end

    it 'rejects duplicate inbox-scoped templates' do
      account = create(:account)
      inbox = create(:inbox, :with_email, account: account)
      create(:email_template, account: account, inbox: inbox)
      duplicate_template = build(:email_template, account: account, inbox: inbox)

      expect(duplicate_template).not_to be_valid
      expect(duplicate_template.errors[:name]).to include('has already been taken')
    end

    it 'requires branded layouts to include content_for_layout' do
      template = build(:email_template, name: EmailTemplate::BRANDED_LAYOUT_NAME, template_type: :layout, body: '<html><body>No slot</body></html>')

      expect(template).not_to be_valid
      expect(template.errors[:body]).to include('must include {{ content_for_layout }}')
    end

    it 'validates liquid syntax' do
      template = build(:email_template, body: '{{ broken ')

      expect(template).not_to be_valid
      expect(template.errors[:body].first).to include('has invalid Liquid syntax')
    end

    it 'requires account to match inbox account when both are present' do
      inbox = create(:inbox, :with_email)
      other_account = create(:account)
      template = build(:email_template, :layout, account: other_account, inbox: inbox)

      expect(template).not_to be_valid
      expect(template.errors[:account]).to include('must match inbox account')
    end
  end

  describe '.branded_layout_for' do
    it 'uses inbox, account, then installation fallback order' do
      account = create(:account)
      inbox = create(:inbox, :with_email, account: account)
      create(:email_template, :layout, body: 'Global {{ content_for_layout }}')
      account_template = create(:email_template, :layout, account: account, body: 'Account {{ content_for_layout }}')

      expect(described_class.branded_layout_for(inbox: inbox, account: account, locale: :en)).to eq(account_template)

      inbox_template = create(:email_template, :layout, account: account, inbox: inbox, body: 'Inbox {{ content_for_layout }}')

      expect(described_class.branded_layout_for(inbox: inbox, account: account, locale: :en)).to eq(inbox_template)
    end
  end

  describe '.update_account_branded_layout!' do
    it 'creates and updates the account-scoped branded layout' do
      account = create(:account)

      described_class.update_account_branded_layout!(account: account, body: 'Account {{ content_for_layout }}')

      template = described_class.account_branded_layout_template_for(account)
      expect(template.body).to eq('Account {{ content_for_layout }}')

      described_class.update_account_branded_layout!(account: account, body: 'Updated {{ content_for_layout }}')

      expect(template.reload.body).to eq('Updated {{ content_for_layout }}')
    end

    it 'clears the account-scoped branded layout for blank bodies' do
      account = create(:account)
      create(:email_template, :layout, account: account)

      described_class.update_account_branded_layout!(account: account, body: '')

      expect(described_class.account_branded_layout_template_for(account)).to be_nil
    end
  end
end
