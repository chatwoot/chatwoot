require 'rails_helper'

RSpec.describe KnowledgeBase do
  let(:account) { create(:account) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }

    context 'when source_type is webpage' do
      it 'validates presence of url' do
        knowledge_base = build(:knowledge_base, :webpage, account: account)
        knowledge_base.url = nil
        expect(knowledge_base).not_to be_valid
        expect(knowledge_base.errors[:url]).to include("can't be blank")
      end

      it 'allows valid URLs' do
        knowledge_base = build(:knowledge_base, :webpage, account: account)
        expect(knowledge_base).to be_valid
      end
    end

    context 'when source_type is file or image' do
      it 'allows valid file type' do
        knowledge_base = build(:knowledge_base, :file, account: account)
        expect(knowledge_base).to be_valid
      end

      it 'allows valid image type' do
        knowledge_base = build(:knowledge_base, :image, account: account)
        expect(knowledge_base).to be_valid
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many_attached(:files) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:source_type).with_values(webpage: 0, file: 1, image: 2) }
  end

  describe 'factory' do
    it 'creates a valid knowledge_base' do
      knowledge_base = create(:knowledge_base)
      expect(knowledge_base).to be_valid
      expect(knowledge_base.id).to be_present
      expect(knowledge_base.account).to be_present
    end

    it 'creates a valid webpage knowledge_base' do
      knowledge_base = create(:knowledge_base, :webpage)
      expect(knowledge_base).to be_valid
      expect(knowledge_base.source_type).to eq('webpage')
      expect(knowledge_base.url).to be_present
    end

    it 'creates a valid file knowledge_base' do
      knowledge_base = create(:knowledge_base, :file)
      expect(knowledge_base).to be_valid
      expect(knowledge_base.source_type).to eq('file')
    end

    it 'creates a valid image knowledge_base' do
      knowledge_base = create(:knowledge_base, :image)
      expect(knowledge_base).to be_valid
      expect(knowledge_base.source_type).to eq('image')
    end
  end

  describe 'UUID primary key' do
    it 'generates UUID for id' do
      knowledge_base = create(:knowledge_base)
      expect(knowledge_base.id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it 'uses custom UUID when provided' do
      custom_uuid = SecureRandom.uuid
      knowledge_base = create(:knowledge_base, id: custom_uuid)
      expect(knowledge_base.id).to eq(custom_uuid)
    end
  end
end