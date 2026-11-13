require 'rails_helper'

RSpec.describe Captain::Copilot::Actions do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  it 'keeps the other custom attributes and refuses keys the account has not defined' do
    create(:custom_attribute_definition, account: account, attribute_model: :conversation_attribute, attribute_key: 'plan')
    conversation.update!(custom_attributes: { 'region' => 'eu' })

    action = described_class.build('set_custom_attributes', account: account, user: admin, arguments: { attributes: { plan: 'pro' } })

    expect(action.perform(conversation)).to eq(:applied)
    expect(conversation.reload.custom_attributes).to eq('region' => 'eu', 'plan' => 'pro')
    expect { described_class.build('set_custom_attributes', account: account, user: admin, arguments: { attributes: { tier: 'gold' } }) }
      .to raise_error(ArgumentError, /Unknown attributes: tier/)
  end

  it 'adds inbox members as participants and refuses agents outside the inbox' do
    member = create(:user, account: account, role: :agent)
    create(:inbox_member, user: member, inbox: inbox)
    outsider = create(:user, account: account, role: :agent)

    add_member = described_class.build('add_participants', account: account, user: admin, arguments: { user_ids: [member.id] })
    add_outsider = described_class.build('add_participants', account: account, user: admin, arguments: { user_ids: [outsider.id] })

    expect(add_member.perform(conversation)).to eq(:applied)
    expect(conversation.conversation_participants.pluck(:user_id)).to eq([member.id])
    expect { add_outsider.perform(conversation) }
      .to raise_error(Captain::Copilot::ActionNotApplicableError, "Not members of the #{inbox.name} inbox: #{outsider.name}")
  end

  it 'mutes a conversation by resolving it and blocking its contact, once' do
    action = described_class.build('mute', account: account, user: admin, arguments: {})

    expect(action.perform(conversation)).to eq(:applied)
    expect(conversation.reload).to be_resolved
    expect(conversation.contact.reload).to be_blocked
    expect(action.perform(conversation)).to eq(:skipped)
  end

  it 'resolves every conversation of a contact the change has already blocked' do
    action = described_class.build('mute', account: account, user: admin, arguments: {})
    other_conversation = create(:conversation, account: account, inbox: inbox, contact: conversation.contact)

    action.perform(conversation)

    expect(action.perform(other_conversation.reload)).to eq(:applied)
    expect(other_conversation.reload).to be_resolved
  end

  it 'labels and notes contacts with the conversation label rules' do
    create(:label, account: account, title: 'vip')
    contact = conversation.contact

    expect(described_class.build('add_contact_labels', account: account, user: admin, arguments: { labels: ['vip'] }).perform(contact))
      .to eq(:applied)
    described_class.build('add_contact_note', account: account, user: admin, arguments: { content: 'Asked for a refund' }).perform(contact)

    expect(contact.reload.label_list).to eq(['vip'])
    expect(contact.notes.pluck(:content, :user_id)).to eq([['Asked for a refund', admin.id]])
    expect { described_class.build('add_contact_labels', account: account, user: admin, arguments: { labels: ['gold'] }) }
      .to raise_error(ArgumentError, /Unknown labels: gold/)
  end
end
