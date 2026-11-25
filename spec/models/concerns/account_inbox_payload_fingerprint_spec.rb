require 'rails_helper'

RSpec.describe AccountInboxPayloadFingerprint do
  let(:account) { create(:account) }

  def inbox_key
    account.cache_keys[:inbox]
  end

  it 'leaves the other models untouched' do
    expect(account.cache_keys.keys).to contain_exactly(:label, :inbox, :team, :canned_response)
    expect(account.cache_keys[:label]).not_to include('-')
  end

  # The browser validates its cached rows against this key, and an inbox write is the only
  # thing that used to move it. A deployment that turns groups off left every warm cache
  # serving inboxes that still claim the capability, so the composer stayed enabled and the
  # server refused what it sent.
  it 'changes when the groups kill switch is flipped' do
    with_modified_env WHATSAPP_GROUPS_ENABLED: 'true' do
      enabled = inbox_key

      with_modified_env WHATSAPP_GROUPS_ENABLED: 'false' do
        expect(inbox_key).not_to eq(enabled)
      end
    end
  end

  # The version is what covers the third case, and it is the one with no runtime signal at
  # all: a capability added to a descriptor changes what the payload carries while the
  # record, the env and the payload's shape all stay put. Nothing here can detect that the
  # bump was forgotten, so this asserts the only thing it can -- that the version is part
  # of the key, and that moving it moves the key.
  it 'changes when the payload version is bumped' do
    before_bump = inbox_key

    stub_const('AccountInboxPayloadFingerprint::PAYLOAD_VERSION',
               AccountInboxPayloadFingerprint::PAYLOAD_VERSION + 1)

    expect(inbox_key).not_to eq(before_bump)
  end

  # Not a capability, and older than this concern: the same gap applies to anything in the
  # payload that comes from configuration rather than from the record.
  it 'changes when the inbound email domain is configured' do
    with_modified_env MAILER_INBOUND_EMAIL_DOMAIN: nil do
      without = inbox_key

      with_modified_env MAILER_INBOUND_EMAIL_DOMAIN: 'mail.example.com' do
        expect(inbox_key).not_to eq(without)
      end
    end
  end

  it 'still moves when an inbox changes' do
    before_write = inbox_key
    create(:inbox, account: account)

    expect(inbox_key).not_to eq(before_write)
  end

  # The browser compares this verbatim against what it stored, so the suffix has to be
  # deterministic for a given configuration rather than merely different each time.
  it 'appends a stable suffix to the key the account already served' do
    base = account.send(:fetch_value_for_key, account.id, 'inbox')

    expect(inbox_key).to match(/\A#{Regexp.escape(base)}-[0-9a-f]{8}\z/)
    expect(inbox_key).to eq(account.cache_keys[:inbox])
  end
end
