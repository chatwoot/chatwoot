# == Schema Information
#
# Table name: notes
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  contact_id :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_notes_on_account_id  (account_id)
#  index_notes_on_contact_id  (contact_id)
#  index_notes_on_user_id     (user_id)
#
require 'rails_helper'

RSpec.describe Note do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:contact_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:contact) }
  end

  describe 'validates_factory' do
    it 'creates valid note object' do
      note = create(:note)
      expect(note.content).to eq 'Hey welcome to chatwoot'
    end
  end
end
