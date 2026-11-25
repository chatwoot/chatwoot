# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Current do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  describe '.isolate' do
    before do
      described_class.account = account
      described_class.user = user
    end

    it 'runs the block against a clean Current' do
      inside = nil

      described_class.isolate { inside = [described_class.account, described_class.user] }

      expect(inside).to eq([nil, nil])
    end

    it 'restores what the caller had set' do
      described_class.isolate { described_class.account = create(:account) }

      expect(described_class.account).to eq(account)
      expect(described_class.user).to eq(user)
    end

    it 'restores it even when the block raises' do
      expect { described_class.isolate { raise 'boom' } }.to raise_error('boom')

      expect(described_class.account).to eq(account)
    end
  end
end
