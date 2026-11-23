require 'rails_helper'

RSpec.describe ContactIdentity::SigningKey do
  let(:inbox) { create(:inbox) }

  it 'generates a secret long enough for HS256 when it is created' do
    signing_key = described_class.create!(inbox: inbox)

    expect(signing_key.secret.bytesize).to be >= 32
  end

  it 'allows two keys for an inbox' do
    described_class.create!(inbox: inbox)

    expect(described_class.new(inbox: inbox)).to be_valid
  end

  it 'does not allow a third key for an inbox' do
    create_list(:contact_identity_signing_key, 2, inbox: inbox)
    signing_key = described_class.new(inbox: inbox)

    expect(signing_key).not_to be_valid
    expect(signing_key.errors[:base]).to include('An inbox can have at most 2 signing keys')
  end

  it 'counts only the keys of its own inbox' do
    create_list(:contact_identity_signing_key, 2, inbox: create(:inbox))

    expect(described_class.new(inbox: inbox)).to be_valid
  end
end
