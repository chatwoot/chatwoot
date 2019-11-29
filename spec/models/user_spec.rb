# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  image                  :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string           not null
#  nickname               :string
#  provider               :string           default("email"), not null
#  pubsub_token           :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("agent")
#  sign_in_count          :integer          default(0), not null
#  tokens                 :json
#  uid                    :string           default(""), not null
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :integer          not null
#  inviter_id             :bigint
#
# Indexes
#
#  index_users_on_email                 (email)
#  index_users_on_inviter_id            (inviter_id)
#  index_users_on_pubsub_token          (pubsub_token) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_uid_and_provider      (uid,provider) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (inviter_id => users.id) ON DELETE => nullify
#


require 'rails_helper'

RSpec.describe User do
  context 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  context 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inviter).class_name('User').required(false) }

    it do
      is_expected.to have_many(:assigned_conversations)
        .class_name('Conversation').dependent(:nullify)
    end
    it { is_expected.to have_many(:inbox_members).dependent(:destroy) }
    it { is_expected.to have_many(:assigned_inboxes).through(:inbox_members) }
    it { is_expected.to have_many(:messages) }
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
