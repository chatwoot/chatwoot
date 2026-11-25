require 'rails_helper'

RSpec.describe Whatsapp::Session::Model::GroupInfo do
  let(:model) { Whatsapp::Session::Model }
  let(:group) { model::Address.group('120363041234567890') }

  # WhatsApp answers every edit of such a group's description with a conflict, whatever
  # the stanza looks like, and a conflict on its own says nothing: another admin writing
  # between the read and the write produces the same answer. This exact string is the only
  # thing that separates the two, which is why the provider passes it on raw.
  it 'reads a description as frozen only at the one value that means it' do
    frozen = described_class.new(group: group, topic_id: 'undefined')

    expect(frozen).to be_description_frozen
  end

  it 'reads an ordinary description id as changeable' do
    ordinary = described_class.new(group: group, topic_id: '3EB0C7A1B2C3D4E5F6')

    expect(ordinary).not_to be_description_frozen
  end

  # Absent is a third answer and not a quieter version of "changeable": uazapi reports no
  # id at all. It reads as not-frozen here because the predicate answers one question, and
  # it is the syncer that refuses to write anything down for a provider that did not say.
  it 'does not call a description frozen when the provider reports no id' do
    unreported = described_class.new(group: group)

    expect(unreported).not_to be_description_frozen
    expect(unreported.topic_id).to be_nil
  end

  it 'takes the id off the wire' do
    parsed = described_class.from_h('group' => { 'kind' => 'group', 'id' => '120363041234567890' },
                                    'subject' => 'Equipe de Vendas', 'topic_id' => 'undefined')

    expect(parsed).to be_description_frozen
  end

  # `to_h` drops nils, so a group whose provider says nothing about the id round-trips
  # against the golden fixtures without growing a member the producer never sent.
  it 'leaves the id out of a payload that never carried one' do
    payload = described_class.new(group: group, subject: 'Equipe de Vendas').to_h

    expect(payload).not_to have_key('topic_id')
  end
end
