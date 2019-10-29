# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Inbox do
  context 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  context 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:channel) }

    it { is_expected.to have_many(:contact_inboxes).dependent(:destroy) }
    it { is_expected.to have_many(:contacts).through(:contact_inboxes) }
    it { is_expected.to have_many(:inbox_members).dependent(:destroy) }
    it do
      is_expected.to have_many(:members).through(:inbox_members).source(:user)
    end
    it { is_expected.to have_many(:conversations).dependent(:destroy) }
    it { is_expected.to have_many(:messages).through(:conversations) }
  end
end
