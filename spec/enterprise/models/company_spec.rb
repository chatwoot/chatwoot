require 'rails_helper'

RSpec.describe Company, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_length_of(:description).is_at_most(1000) }

    describe 'domain validation' do
      it { is_expected.to allow_value('example.com').for(:domain) }
      it { is_expected.to allow_value('sub.example.com').for(:domain) }
      it { is_expected.to allow_value('').for(:domain) }
      it { is_expected.to allow_value(nil).for(:domain) }
      it { is_expected.not_to allow_value('invalid-domain').for(:domain) }
      it { is_expected.not_to allow_value('.example.com').for(:domain) }
    end
  end

  describe 'twenty_id uniqueness' do
    let(:account) { create(:account) }

    it 'enforces account-scoped uniqueness' do
      create(:company, account: account, twenty_id: 'company-123')

      duplicate = build(:company, account: account, twenty_id: 'company-123')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:twenty_id]).to include('has already been taken')
    end

    it 'allows the same twenty_id in another account' do
      create(:company, account: account, twenty_id: 'company-123')
      other_account_company = build(:company, account: create(:account), twenty_id: 'company-123')

      expect(other_account_company).to be_valid
    end
  end

  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:contacts).dependent(:nullify) }
  end

  describe 'scopes' do
    let(:account) { create(:account) }
    let!(:company_b) { create(:company, name: 'B Company', account: account) }
    let!(:company_a) { create(:company, name: 'A Company', account: account) }
    let!(:company_c) { create(:company, name: 'C Company', account: account) }

    describe '.ordered_by_name' do
      it 'orders companies by name alphabetically' do
        companies = described_class.where(account: account).ordered_by_name
        expect(companies.map(&:name)).to eq([company_a.name, company_b.name, company_c.name])
      end
    end
  end
end
