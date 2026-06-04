# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InboxSignature do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:inbox) }
  end

  describe 'validations' do
    subject { create(:inbox_signature, user: user, inbox: inbox) }

    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }
    let(:inbox) { create(:inbox, account: account) }

    it { is_expected.to validate_presence_of(:message_signature) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:inbox_id) }
    it { is_expected.to validate_inclusion_of(:signature_position).in_array(%w[top bottom]) }
    it { is_expected.to validate_inclusion_of(:signature_separator).in_array(%w[blank --]) }
  end
end
