# frozen_string_literal: true

# == Schema Information
#
# Table name: contacts
#
#  id           :integer          not null, primary key
#  avatar       :string
#  email        :string
#  name         :string
#  phone_number :string
#  pubsub_token :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#
# Indexes
#
#  index_contacts_on_account_id    (account_id)
#  index_contacts_on_pubsub_token  (pubsub_token) UNIQUE
#


require 'rails_helper'

RSpec.describe Contact do
  context 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  context 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:conversations).dependent(:destroy) }
  end

  describe 'pubsub_token' do
    let(:user) { create(:user) }

    it 'gets created on object create' do
      obj = user
      expect(obj.pubsub_token).not_to eq(nil)
    end

    it 'does not get updated on object update' do
      obj = user
      old_token = obj.pubsub_token
      obj.update(name: 'test')
      expect(obj.pubsub_token).to eq(old_token)
    end
  end
end
