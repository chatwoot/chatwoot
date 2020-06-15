# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notification do
  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  context 'with default order by' do
    it 'sort by primary id desc' do
      notification1 = create(:notification)
      create(:notification)
      notification3 = create(:notification)

      expect(described_class.all.first).to eq notification3
      expect(described_class.all.last).to eq notification1
    end
  end
end
