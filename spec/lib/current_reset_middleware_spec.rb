# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurrentResetMiddleware do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  def run(&)
    described_class.new.call(nil, {}, 'default', &)
  end

  it 'clears what the job left behind' do
    run do
      Current.account = account
      Current.user = user
    end

    expect(Current.account).to be_nil
    expect(Current.user).to be_nil
  end

  it 'clears it even when the job raises' do
    expect { run { Current.account = account and raise 'boom' } }.to raise_error('boom')

    expect(Current.account).to be_nil
  end

  it 'returns what the job returned' do
    expect(run { :done }).to eq(:done)
  end

  # Only on the way out. Nothing about Current crosses the queue, so a job that needs it
  # sets its own; clearing on entry would suggest a caller could hand one down.
  it 'leaves Current alone on the way in' do
    Current.account = account
    seen = nil

    run { seen = Current.account }

    expect(seen).to eq(account)
  end
end
