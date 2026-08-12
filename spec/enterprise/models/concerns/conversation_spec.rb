# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversation do
  let(:account) { create(:account, :without_package) }
  let(:package) { create(:package, conversations_limit: 1) }
  let(:inbox) { create(:inbox, account: account) }

  before { create(:account_package, account: account, package: package) }

  it 'allows conversations within the limit' do
    expect { create(:conversation, account: account, inbox: inbox) }.not_to raise_error
  end

  it 'raises when the account has reached its monthly conversations limit' do
    create(:conversation, account: account, inbox: inbox)

    expect { create(:conversation, account: account, inbox: inbox) }
      .to raise_error(CustomExceptions::Conversation::LimitExceeded, 'Account limit exceeded. Upgrade to a higher plan')
  end

  it 'does not enforce a limit when the package limit is nil' do
    package.update!(conversations_limit: nil)

    expect { create_list(:conversation, 2, account: account, inbox: inbox) }.not_to raise_error
  end
end
