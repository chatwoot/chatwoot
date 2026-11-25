require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::ContactResolver do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:party) { model::Party.new(phone: '5541999990000', lid: '182736451928374', push_name: 'Ana Souza') }

  it 'keys the contact_inbox by LID and fills the contact in' do
    contact_inbox = described_class.new(inbox: inbox, party: party, overwrite: true).perform

    expect(contact_inbox.source_id).to eq('182736451928374')
    expect(contact_inbox.contact).to have_attributes(
      name: 'Ana Souza', phone_number: '+5541999990000', identifier: '182736451928374@lid'
    )
  end

  # Consolidation needs a phone *and* a LID, so it can do nothing for a phone-only
  # party. Without a variant-aware lookup the builder matches exactly, misses the row
  # the contact is already filed under, and files the same person a second time with a
  # conversation of their own.
  context 'when the contact is already filed under the other ninth-digit form' do
    let(:party) { model::Party.new(phone: '5541988887777', push_name: 'Bruno') }
    let!(:existing) do
      contact = create(:contact, account: channel.account, phone_number: '+554188887777')
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: '554188887777')
    end

    it 'reuses it instead of creating a second contact' do
      expect { described_class.new(inbox: inbox, party: party, overwrite: true).perform }
        .not_to change(inbox.contact_inboxes, :count)

      expect(described_class.new(inbox: inbox, party: party, overwrite: true).perform.id).to eq(existing.id)
    end
  end

  # An unordered `IN` over both forms can hand back either row. Picking the alternate
  # one files the message under the wrong contact, and `overwrite` then tries to move
  # the exact number onto a contact that does not own it, which the uniqueness check
  # refuses: the message is lost rather than merely misfiled.
  context 'when both ninth-digit forms are already filed' do
    let(:party) { model::Party.new(phone: '5541988887777', push_name: 'Bruno') }
    let!(:exact) do
      contact = create(:contact, account: channel.account, name: 'Bruno Exato', phone_number: '+5541988887777')
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: '5541988887777')
    end

    before do
      contact = create(:contact, account: channel.account, name: 'Bruno Antigo', phone_number: '+554188887777')
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: '554188887777')
    end

    it 'files the message under the number as reported' do
      expect(described_class.new(inbox: inbox, party: party, overwrite: true).perform.id).to eq(exact.id)
    end
  end

  # A contact created by hand or through the API has no contact_inbox yet, so the
  # variant lookup above, which reads this inbox's contact_inboxes, cannot see it. The
  # builder then matched the number exactly and filed a second, unblocked contact that
  # an agent bot answered (#776).
  context 'when a contact with no contact_inbox holds the other ninth-digit form' do
    lids = [nil, '182736451928374']

    [
      ['5541988887777', '+554188887777', 'the message has the ninth digit'],
      ['554188887777', '+5541988887777', 'the message has no ninth digit']
    ].each do |reported, stored, label|
      context "when #{label}" do
        let!(:existing) { create(:contact, account: channel.account, name: 'Bruno', phone_number: stored, blocked: true) }

        lids.each do |lid|
          it "files it under that contact#{' with a LID' if lid}" do
            party = model::Party.new(phone: reported, lid: lid, push_name: 'Bruno')

            expect { described_class.new(inbox: inbox, party: party, overwrite: true).perform }
              .not_to change(channel.account.contacts, :count)

            contact_inbox = inbox.contact_inboxes.sole
            expect(contact_inbox.contact_id).to eq(existing.id)
            expect(existing.reload.blocked).to be(true)
          end
        end
      end
    end

    # Argentina's source-id variant drops the mobile 9, which is a landline number that can
    # belong to somebody else.
    it 'does not take an Argentine landline for the mobile that reported' do
      landline = create(:contact, account: channel.account, name: 'Fixo', phone_number: '+541123456789')

      expect { described_class.new(inbox: inbox, party: model::Party.new(phone: '5491123456789', push_name: 'Movil')).perform }
        .to change(channel.account.contacts, :count).by(1)
      expect(landline.reload.phone_number).to eq('+541123456789')
    end

    it 'does not reach a contact of another account' do
      create(:contact, phone_number: '+554188887777')

      expect { described_class.new(inbox: inbox, party: model::Party.new(phone: '5541988887777', push_name: 'Bruno')).perform }
        .to change(channel.account.contacts, :count).by(1)
    end
  end

  # A message can arrive keyed only by LID, with no number to look the contact up by.
  it 'files a party that has only a LID' do
    contact_inbox = described_class.new(inbox: inbox, party: model::Party.new(lid: '182736451928374', push_name: 'Ana')).perform

    expect(contact_inbox.source_id).to eq('182736451928374')
    expect(contact_inbox.contact.phone_number).to be_nil
  end

  it 'answers nil for a party with nothing to key on' do
    expect(described_class.new(inbox: inbox, party: model::Party.new(push_name: 'Ana')).perform).to be_nil
  end

  # A conversion or an import leaves the number formatted, and only stripping the plus
  # left the separators behind, so the digit check failed and the contact kept showing
  # as a phone number forever.
  it 'replaces a name that is the phone number written out' do
    contact = create(:contact, account: channel.account, name: '+55 41 99999-0000', phone_number: '+5541999990000')
    create(:contact_inbox, inbox: inbox, contact: contact, source_id: '5541999990000')

    described_class.new(inbox: inbox, party: model::Party.new(phone: '5541999990000', push_name: 'Ana Souza'),
                        overwrite: true).perform

    expect(contact.reload.name).to eq('Ana Souza')
  end

  it 'keeps a real name that happens to carry a digit' do
    contact = create(:contact, account: channel.account, name: 'Ana 2', phone_number: '+5541999990000')
    create(:contact_inbox, inbox: inbox, contact: contact, source_id: '5541999990000')

    described_class.new(inbox: inbox, party: model::Party.new(phone: '5541999990000', push_name: 'Ana Souza'),
                        overwrite: true).perform

    expect(contact.reload.name).to eq('Ana 2')
  end

  it 'replaces a name that is only the contact phone number' do
    contact = create(:contact, account: channel.account, name: '5541999990000', phone_number: '+5541999990000')
    create(:contact_inbox, contact: contact, inbox: inbox, source_id: '182736451928374')

    described_class.new(inbox: inbox, party: party, overwrite: true).perform

    expect(contact.reload.name).to eq('Ana Souza')
  end

  it 'keeps a name a human typed' do
    contact = create(:contact, account: channel.account, name: 'Ana (financeiro)', phone_number: '+5541999990000')
    create(:contact_inbox, contact: contact, inbox: inbox, source_id: '182736451928374')

    described_class.new(inbox: inbox, party: party, overwrite: true).perform

    expect(contact.reload.name).to eq('Ana (financeiro)')
  end

  it 'only fills blanks for a group participant' do
    contact = create(:contact, account: channel.account, name: 'Ana', phone_number: '+5541999999999')
    create(:contact_inbox, contact: contact, inbox: inbox, source_id: '182736451928374')

    described_class.new(inbox: inbox, party: party).perform

    expect(contact.reload.phone_number).to eq('+5541999999999')
  end

  it 'merges a contact_inbox that was keyed by phone before the LID showed up' do
    contact = create(:contact, account: channel.account, name: 'Ana', phone_number: '+5541999990000')
    create(:contact_inbox, contact: contact, inbox: inbox, source_id: '5541999990000')

    contact_inbox = described_class.new(inbox: inbox, party: party, overwrite: true).perform

    expect(contact_inbox.contact_id).to eq(contact.id)
    expect(inbox.contacts.count).to eq(1)
  end

  it 'asks for the profile picture of a contact that has none' do
    contact_inbox = described_class.new(inbox: inbox, party: party, overwrite: true).perform

    expect(Whatsapp::Session::UpdateContactAvatarJob).to have_been_enqueued.with(contact_inbox.contact, inbox, party.to_h)
  end
end
