require 'rails_helper'

# An announcement that speaks of a body says which body, and the rules are only asked about it while the
# row still holds it. The conditions are evaluated in SQL over the row, never over the payload, and the
# evaluation runs long after the dispatch: a write landing in between would have the rules answer about
# a body the announcement is not about (fazer-ai/chatwoot#661).
#
# The comparison is on the body and not on the edit marker. A row an edit reached first still recovers
# into the same text often enough -- a contact who corrects a typo before the encrypted original lands --
# and standing the arrival's rules down there would cost the #491 delivery for no reason.
#
# `message_created` is deliberately outside all of this: an arrival is about the row appearing, and it
# keeps answering about whatever the row says when the work runs.
RSpec.describe 'automations and the body an announcement is about' do # rubocop:disable RSpec/DescribeClass
  include ActiveJob::TestHelper

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:account) { inbox.account }

  let(:model) { Whatsapp::Session::Model }
  let(:sender) { model::Party.new(phone: '5541999990000', lid: '182736451928374', push_name: 'Ana Souza') }
  let(:chat) { model::Address.phone('5541999990000') }
  let(:placeholder) { model::Content::Unsupported.new(reason: 'undecryptable') }
  let(:recovered) { model::Content::Text.new(body: 'quero saber o preço') }
  let(:inbound) do
    model::InboundMessage.new(
      id: '3EB0INVAR001', chat: chat, sender: sender, from_me: false,
      timestamp: 1_755_440_000_123, content: placeholder
    )
  end

  let!(:on_orcamento) { rule('CR_ORC', 'message_created', [condition('content', 'contains', ['orçamento'])]) }
  let!(:on_preco) { rule('CR_PRECO', 'message_created', [condition('content', 'contains', ['preço'])]) }
  let!(:on_anything) { rule('CR_QUALQUER', 'message_created', [condition('inbox_id', 'equal_to', [inbox.id])]) }
  let!(:on_edit_orcamento) { rule('ED_ORC', 'message_edited', [condition('content', 'contains', ['orçamento'])]) }
  let!(:on_card) { rule('CR_CARTAO', 'message_created', [condition('content', 'contains', ['Carlos'])]) }

  before do
    allow(channel).to receive(:provider_service).and_return(Whatsapp::Session::Backends::Fake.new(channel))
    # The same chat delivered three times or more goes looking for the avatar behind a connector that is
    # not there, and nothing here measures a contact photo.
    allow(Whatsapp::Session::UpdateContactAvatarJob).to receive(:perform_later)
  end

  def condition(key, operator, values)
    { 'attribute_key' => key, 'filter_operator' => operator, 'values' => values, 'query_operator' => nil }
  end

  def rule(name, event_name, conditions)
    create(:automation_rule, account: account, name: name, event_name: event_name,
                             conditions: conditions,
                             actions: [{ 'action_name' => 'send_message', 'action_params' => [name] }])
  end

  # `ActionService#send_message` stamps the rule id on the message it sends, so this counts executions.
  # `#>>'{}'` first because `content_attributes` is a json column written through `store coder: JSON`:
  # a plain `->>` answers NULL on every row and would count every rule as never run.
  def ran(automation_rule)
    account.messages.where("((content_attributes#>>'{}')::jsonb)->>'automation_rule_id' = ?", automation_rule.id.to_s).count
  end

  def deliver(content, id: inbound.id, mentions: [])
    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageReceived.new(message: inbound.with(id: id, content: content, mentions: mentions)))
    )
  end

  def arrive(content, id: inbound.id, mentions: [])
    deliver(content, id: id, mentions: mentions)
    perform_enqueued_jobs
  end

  def deliver_edit(body, timestamp: 1_755_440_500_000, id: inbound.id)
    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageEdited.new(
                                    chat: chat, message_id: id, timestamp: timestamp,
                                    content: model::Content::Text.new(body: body)
                                  ))
    )
  end

  def edit(body, timestamp: 1_755_440_500_000, id: inbound.id)
    deliver_edit(body, timestamp: timestamp, id: id)
    perform_enqueued_jobs
  end

  def stored
    inbox.messages.find_by(source_id: inbound.id)
  end

  # The sequence the issue was measured on, with nothing failing anywhere: the contact corrects the
  # placeholder into one text and the encrypted original turns out to say another. `reconcile_in_place`
  # keeps the edit, so the row shows a body the recovery never wrote, and the arrival's content rules
  # have no business being asked about it.
  it 'leaves the arrival content rules alone when the recovered body is not the one on the row' do
    arrive(placeholder)
    edit('quero um orçamento')

    arrive(recovered)

    expect(ran(on_orcamento)).to eq(0)
    expect(ran(on_anything)).to eq(1)
    expect(ran(on_edit_orcamento)).to eq(1)
    expect(stored.content).to eq('quero um orçamento')
    expect(inbox.messages.where(source_id: inbound.id).count).to eq(1)
  end

  # And the half that keeps this from being a check on the edit marker. The row carries `is_edited` here
  # exactly as it does above; what differs is that the body the recovery carries is the body the row is
  # showing, so the rule that was asked about a placeholder gets its answer.
  it 'runs them when the recovered body is the one on the row, edit marker and all' do
    arrive(placeholder)
    edit('quero saber o preço')

    arrive(recovered)

    expect(ran(on_preco)).to eq(1)
    expect(ran(on_anything)).to eq(1)
    expect(ran(on_orcamento)).to eq(0)
  end

  # The debt path of #646: the content was committed and only the announcement was lost, so the row
  # carries the debt and a redelivery is the one thing that can pay it. An edit landing in between is
  # what the issue measured, and the body the redelivery carries is still the recovered one.
  it 'pays the recovery debt without evaluating when an edit replaced the recovered body' do
    arrive(placeholder)

    refusing = true
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, timestamp, data|
      raise 'the job transport is away' if refusing && name == Events::Types::MESSAGE_RECOVERED

      original.call(name, timestamp, data)
    end

    expect { deliver(recovered) }.to raise_error('the job transport is away')
    perform_enqueued_jobs
    expect(stored.content).to eq('quero saber o preço')
    expect(stored.content_attributes).not_to include('is_unsupported', 'unsupported_reason')

    refusing = false
    edit('quero um orçamento')
    arrive(recovered)

    expect(ran(on_orcamento)).to eq(0)
    expect(ran(on_anything)).to eq(1)
    expect(ran(on_edit_orcamento)).to eq(1)
    expect(stored.content).to eq('quero um orçamento')
  end

  # The consumer's session cursor only moves forwards, so a debt is only ever reached once that cursor
  # is gone -- and then the whole backlog replays in order, with the placeholder ahead of the message
  # that recovered it. The placeholder carries no body of its own, and it pays the debt all the same,
  # because the debt names the body rather than asking whoever turns up to rebuild it.
  it 'pays the debt from the replayed placeholder, which carries no body of its own' do
    arrive(placeholder)

    refusing = true
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, timestamp, data|
      raise 'the job transport is away' if refusing && name == Events::Types::MESSAGE_RECOVERED

      original.call(name, timestamp, data)
    end
    expect { deliver(recovered) }.to raise_error('the job transport is away')
    perform_enqueued_jobs
    refusing = false

    arrive(placeholder)

    expect(ran(on_preco)).to eq(1)
    expect(ran(on_anything)).to eq(1)
    expect(ran(on_orcamento)).to eq(0)
  end

  # The debt owes an announcement for the body this delivery recovered, and on a row an edit reached
  # first that is not the body the row is showing: `reconcile_in_place` keeps the edit. A debt that
  # named the row's body instead would have the redelivery announce the editor's text as recovered
  # content, which is the defect this whole change is about.
  it 'owes nothing it can announce when the edit that got there first is still what the row shows' do
    arrive(placeholder)
    edit('quero um orçamento')

    refusing = true
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, timestamp, data|
      raise 'the job transport is away' if refusing && name == Events::Types::MESSAGE_RECOVERED

      original.call(name, timestamp, data)
    end
    expect { deliver(recovered) }.to raise_error('the job transport is away')
    perform_enqueued_jobs
    refusing = false

    arrive(recovered)

    expect(ran(on_orcamento)).to eq(0)
    expect(ran(on_preco)).to eq(0)
    expect(ran(on_anything)).to eq(1)
    expect(stored.content).to eq('quero um orçamento')
  end

  # The window between the job picking the work up and the conditions being asked. The job holds the row
  # as it was when it loaded it, and the conditions query the row as it is now, so an edit committing in
  # between would have the rules answer about a body the announcement is not about -- which is what the
  # check exists to stop. Closed by asking inside the lock, against the row that lock reloads.
  #
  # The edit is committed at the top of the listener rather than around the lock, on purpose: hanging it
  # on the lock would make the test depend on the very mechanism under test, and a version that took no
  # lock would pass by never opening the window at all.
  it 'stands down on an edit that commits after the work is picked up' do
    arrive(placeholder)

    allow(AutomationRuleListener.instance).to receive(:message_recovered).and_wrap_original do |original, event|
      Message.where(source_id: inbound.id).update_all(content: 'quero um orçamento') # rubocop:disable Rails/SkipsModelValidations
      original.call(event)
    end

    arrive(recovered)

    expect(ran(on_preco)).to eq(0)
    expect(ran(on_orcamento)).to eq(0)
  end

  # The same question one step earlier, in the delivery that recovers rather than in the one that pays a
  # debt: the body is written, fingerprinted and announced by one delivery, and working it out three
  # times means a rename landing between any two of them makes them disagree. Then the row shows what was
  # stored, the announcement names something else, and the rules are never asked -- about a message
  # nobody edited.
  it 'announces the body it wrote when the mentioned contact is renamed right after the write' do
    mentioned = create(:contact, account: account, name: 'Bruno Antigo', phone_number: '+5541988887777')
    create(:contact_inbox, inbox: inbox, contact: mentioned, source_id: '5541988887777')
    mention = model::Content::Text.new(body: 'quero saber o preço @5541988887777')
    mentions = [model::Address.phone('5541988887777')]

    arrive(placeholder)
    allow_any_instance_of(Whatsapp::Session::Inbound::MessageWriter).to receive(:reconcile).and_wrap_original do |original, row| # rubocop:disable RSpec/AnyInstance
      written = original.call(row)
      mentioned.update!(name: 'Bruno Novo')
      written
    end

    arrive(mention, mentions: mentions)

    expect(stored.content).to include('Bruno Antigo')
    expect(ran(on_preco)).to eq(1)
  end

  # And what the debt owes is the body that was stored, not one rebuilt from whichever delivery gets
  # here: `MessageWriter#message_content` resolves mentions against the contacts as they are now, so a
  # contact renamed in between rebuilds a different string for a message nobody edited.
  it 'pays the debt on a body with a mention after the mentioned contact is renamed' do
    mentioned = create(:contact, account: account, name: 'Bruno Antigo', phone_number: '+5541988887777')
    create(:contact_inbox, inbox: inbox, contact: mentioned, source_id: '5541988887777')
    mention = model::Content::Text.new(body: 'quero saber o preço @5541988887777')
    mentions = [model::Address.phone('5541988887777')]

    arrive(placeholder)
    refusing = true
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, timestamp, data|
      raise 'the job transport is away' if refusing && name == Events::Types::MESSAGE_RECOVERED

      original.call(name, timestamp, data)
    end
    expect { deliver(mention, mentions: mentions) }.to raise_error('the job transport is away')
    perform_enqueued_jobs
    refusing = false
    # The premise: the body that was stored carries the name the contact had, so rebuilding it after
    # the rename produces a different string for a message nobody edited.
    expect(stored.content).to include('Bruno Antigo')

    mentioned.update!(name: 'Bruno Novo')
    arrive(mention, mentions: mentions)

    expect(stored.content).to include('Bruno Antigo')
    expect(ran(on_preco)).to eq(1)
  end

  it 'adds nothing on the redeliveries that follow' do
    arrive(placeholder)
    edit('quero um orçamento')
    arrive(recovered)

    3.times { arrive(recovered) }

    expect(ran(on_orcamento)).to eq(0)
    expect(ran(on_anything)).to eq(1)
    expect(ran(on_edit_orcamento)).to eq(1)
    expect(inbox.messages.where(source_id: inbound.id).count).to eq(1)
  end

  # A share of one contact recovers into the card's line rather than into any text the message carries,
  # so the body it announces is that line. Reading the text would announce nothing here, and the rules
  # that were asked about the placeholder would never be asked again.
  it 'names the line a shared card recovers into' do
    arrive(placeholder)

    arrive(model::Content::Contacts.new(contacts: [{ 'display_name' => 'Carlos Dias', 'phone' => '+5541988881111' }]))

    expect(stored.content).to eq('Carlos Dias - +5541988881111')
    expect(ran(on_card)).to eq(1)
    expect(ran(on_anything)).to eq(1)
  end

  # The fence on the event that is not part of any of this. An arrival's evaluation reads the row when it
  # runs, and an edit committing before it gets there changes the answer -- which is how it has always
  # worked, and is not what a comparison on the announced body would leave standing.
  it 'lets an arrival answer about whatever the row says by the time the work runs' do
    deliver(model::Content::Text.new(body: 'quero saber o preço'), id: '3EB0PLAIN002')
    deliver_edit('quero um orçamento', id: '3EB0PLAIN002')

    perform_enqueued_jobs

    expect(ran(on_orcamento)).to eq(1)
    expect(ran(on_preco)).to eq(0)
    expect(ran(on_edit_orcamento)).to eq(1)
  end
end
