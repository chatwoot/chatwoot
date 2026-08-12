# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contact do
  let(:account) { create(:account, :without_package) }
  let(:package) { create(:package, contacts_limit: 1) }

  before { create(:account_package, account: account, package: package) }

  it 'allows contacts within the limit' do
    expect { create(:contact, account: account) }.not_to raise_error
  end

  it 'raises when the account has reached its contacts limit' do
    create(:contact, account: account)

    expect { create(:contact, account: account) }
      .to raise_error(CustomExceptions::Contact::LimitExceeded, 'Account limit exceeded. Upgrade to a higher plan')
  end

  it 'does not enforce a limit when the package limit is nil' do
    package.update!(contacts_limit: nil)

    expect { create_list(:contact, 2, account: account) }.not_to raise_error
  end
end
