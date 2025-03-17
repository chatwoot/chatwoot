require 'rails_helper'

RSpec.describe SmartVariable, type: :model do
  describe 'validations' do
    subject { create(:smart_variable) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe 'database columns' do
    it { should have_db_column(:name).of_type(:string) }
    it { should have_db_column(:data).of_type(:jsonb) }
    it { should have_db_column(:created_at).of_type(:datetime) }
    it { should have_db_column(:updated_at).of_type(:datetime) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:smart_variable)).to be_valid
    end
  end
end
