require 'rails_helper'

RSpec.describe PipelineStatus, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:conversations).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'callbacks' do
    describe 'before_save :set_name' do
      let(:account) { create(:account) }

      it 'converts name to lowercase' do
        pipeline_status = create(:pipeline_status, account: account, name: 'QUALIFIED')
        expect(pipeline_status.name).to eq('qualified')
      end

      it 'handles mixed case names' do
        pipeline_status = create(:pipeline_status, account: account, name: 'LeAdGeNeRaTeD')
        expect(pipeline_status.name).to eq('leadgenerated')
      end
    end

    describe 'before_destroy :check_for_conversations' do
      let(:account) { create(:account) }
      let(:pipeline_status) { create(:pipeline_status, account: account) }

      context 'when pipeline status has no conversations' do
        it 'allows deletion' do
          expect(pipeline_status.destroy).to be_truthy
          expect(pipeline_status.destroyed?).to be_truthy
        end
      end

      context 'when pipeline status has assigned conversations' do
        let(:inbox) { create(:inbox, account: account) }
        let(:conversation) { create(:conversation, account: account, inbox: inbox, pipeline_status: pipeline_status) }

        before do
          conversation
        end

        it 'prevents deletion' do
          expect(pipeline_status.destroy).to be_falsey
          expect(pipeline_status.destroyed?).to be_falsey
        end

        it 'adds an error to base' do
          pipeline_status.destroy
          expect(pipeline_status.errors[:base]).to include('Cannot delete pipeline status with assigned conversations')
        end
      end
    end
  end

  describe 'default scope' do
    let(:account) { create(:account) }

    it 'orders by created_at in ascending order' do
      third = create(:pipeline_status, account: account, name: 'third', created_at: 3.days.ago)
      first = create(:pipeline_status, account: account, name: 'first', created_at: 5.days.ago)
      second = create(:pipeline_status, account: account, name: 'second', created_at: 4.days.ago)

      expect(PipelineStatus.where(account: account)).to eq([first, second, third])
    end
  end
end
