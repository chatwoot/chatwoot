require 'rails_helper'

# An edit replaces the body of a message that is already stored, and until now nothing asked the
# automations about it: `MESSAGE_UPDATED` reaches no rule, and the edit path dispatched nothing else.
# A rule opts into the new trigger, `message_edited`, and the rules of `message_created` are left
# exactly as they were (fazer-ai/chatwoot#648).
#
# Driven through the session dispatcher with the jobs drained, like the recovery's own spec: what is
# under test is which rules run across two events, and a listener called directly would agree with any
# answer about who dispatched what.
RSpec.describe 'automations on a message that was edited' do # rubocop:disable RSpec/DescribeClass
  include ActiveJob::TestHelper

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:account) { inbox.account }
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }

  let(:model) { Whatsapp::Session::Model }
  let(:sender) { model::Party.new(phone: '5541999990000', lid: '182736451928374', push_name: 'Ana Souza') }
  let(:chat) { model::Address.phone('5541999990000') }
  let(:original) { model::Content::Text.new(body: 'quero saber o preço') }
  let(:inbound) do
    model::InboundMessage.new(
      id: '3EB0EDIT0001', chat: chat, sender: sender, from_me: false,
      timestamp: 1_755_440_000_123, content: original
    )
  end

  let!(:on_edit) { rule('R_EDICAO', 'message_edited', [condition('content', 'contains', ['orçamento'])]) }
  let!(:on_create) { rule('R_CRIACAO', 'message_created', [condition('content', 'contains', ['orçamento'])]) }

  before { allow(channel).to receive(:provider_service).and_return(backend) }

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

  def arrive(content = original)
    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageReceived.new(message: inbound.with(content: content)))
    )
    perform_enqueued_jobs
  end

  def deliver_edit(body, timestamp: 1_755_440_500_000)
    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageEdited.new(
                                    chat: chat, message_id: inbound.id, timestamp: timestamp,
                                    content: model::Content::Text.new(body: body)
                                  ))
    )
  end

  def edit(body, timestamp: 1_755_440_500_000)
    deliver_edit(body, timestamp: timestamp)
    perform_enqueued_jobs
  end

  it 'runs a rule of the new trigger when the contact edits the message into a match' do
    arrive
    expect(ran(on_edit)).to eq(0)

    edit('quero um orçamento')

    expect(ran(on_edit)).to eq(1)
  end

  # The promise to every rule that already exists: an edit is not a second creation, and a rule written
  # against `message_created` keeps answering only to arrivals.
  it 'leaves the message_created rules out of it' do
    arrive
    edit('quero um orçamento')

    expect(ran(on_create)).to eq(0)
  end

  it 'evaluates the condition against the edited body instead of firing every rule of the trigger' do
    arrive
    edit('deixa pra lá')

    expect(ran(on_edit)).to eq(0)
  end

  # The case this issue was opened for: the row was stored unreadable, so the arrival had no body to
  # match, and the edit is the first readable thing that row ever had.
  it 'runs on the edit that gives a placeholder its first readable body' do
    arrive(model::Content::Unsupported.new(reason: 'undecryptable'))
    expect(ran(on_edit)).to eq(0)

    edit('quero um orçamento')

    expect(ran(on_edit)).to eq(1)
  end

  # The recovery writes the first readable body onto a placeholder, and that is not an edit: nobody
  # changed what was said. Guarding on the body changing alone, without asking the row whether an edit
  # is what changed it, runs the edit rules on every recovery.
  it 'runs nothing when a placeholder simply recovers, with no edit involved' do
    arrive(model::Content::Unsupported.new(reason: 'undecryptable'))

    arrive(model::Content::Text.new(body: 'quero um orçamento'))

    expect(ran(on_edit)).to eq(0)
  end

  # Two edits are two events. A claim per rule and message, which is what the arrival and the recovery
  # share, would let only the first of them run.
  it 'runs again on a second, different edit of the same message' do
    arrive
    edit('quero um orçamento', timestamp: 1_755_440_500_000)

    edit('quero um orçamento hoje', timestamp: 1_755_440_600_000)

    expect(ran(on_edit)).to eq(2)
  end

  # Nothing orders the announcement against the job that evaluates it. Two edits committing before
  # either job runs leave both evaluations reading the same stored body, because the conditions are
  # asked of the row and not of the event, and two runs of one rule would send the reply twice.
  it 'runs once when two edits commit before either evaluation' do
    arrive
    deliver_edit('deixa pra lá', timestamp: 1_755_440_500_000)
    deliver_edit('quero um orçamento', timestamp: 1_755_440_600_000)

    perform_enqueued_jobs

    expect(ran(on_edit)).to eq(1)
  end

  # The provider resends events, and an edit applied twice writes the same body. Nothing changed, so
  # nothing is announced.
  it 'runs once when the connector redelivers the same edit' do
    arrive
    edit('quero um orçamento')

    edit('quero um orçamento')

    expect(ran(on_edit)).to eq(1)
  end

  # An edit older than the one already applied is refused by the handler, so there is no new body and
  # no event: a rule must not run on a body the row rejected.
  it 'runs nothing when the edit is refused for being older than the stored one' do
    arrive
    edit('deixa pra lá', timestamp: 1_755_440_600_000)

    edit('quero um orçamento', timestamp: 1_755_440_500_000)

    expect(ran(on_edit)).to eq(0)
  end

  # A receipt writes the row too, and it is the reason this trigger is not `MESSAGE_UPDATED`: every
  # outgoing message would otherwise evaluate every rule once or twice more.
  it 'runs nothing on a delivery receipt' do
    arrive
    edit('quero um orçamento')

    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageReceipt.new(
                                    chat: chat, message_ids: [inbound.id], type: 'read',
                                    timestamp: 1_755_440_700_000
                                  ))
    )
    perform_enqueued_jobs

    expect(ran(on_edit)).to eq(1)
  end

  # The announcement itself, and not only what it costs downstream. The claim keyed on the body hides a
  # wrong announcement whenever the body is one this rule already ran on, which is exactly the case
  # below: the rule count stays right while an edit nobody made is published to every listener.
  describe 'what is announced as an edit' do
    before { allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original }

    def announced
      Rails.configuration.dispatcher
    end

    it 'announces the contact edit, once' do
      arrive
      edit('quero um orçamento')

      expect(announced).to have_received(:dispatch).with(Events::Types::MESSAGE_EDITED, anything, anything).once
    end

    it 'announces nothing when a placeholder recovers with no edit involved' do
      arrive(model::Content::Unsupported.new(reason: 'undecryptable'))

      arrive(model::Content::Text.new(body: 'quero um orçamento'))

      expect(announced).not_to have_received(:dispatch).with(Events::Types::MESSAGE_EDITED, anything, anything)
    end

    it 'announces nothing when the recovery lands on a row that was edited first' do
      arrive(model::Content::Unsupported.new(reason: 'undecryptable'))
      edit('quero um orçamento')

      arrive(model::Content::Text.new(body: 'quero saber o preço'))

      expect(announced).to have_received(:dispatch).with(Events::Types::MESSAGE_EDITED, anything, anything).once
    end

    it 'announces nothing on a delivery receipt' do
      arrive

      Whatsapp::Session::Inbound::Dispatcher.dispatch(
        channel, model::Event.build(model::Events::MessageReceipt.new(
                                      chat: chat, message_ids: [inbound.id], type: 'read',
                                      timestamp: 1_755_440_700_000
                                    ))
      )
      perform_enqueued_jobs

      expect(announced).not_to have_received(:dispatch).with(Events::Types::MESSAGE_EDITED, anything, anything)
    end
  end

  # The delayed recovery of a row an edit already settled writes everything around the body and leaves
  # the body alone, on a row that still carries the edit marker. Guarding on the marker alone would
  # announce an edit nobody made.
  it 'runs nothing when the recovery lands on a row that was edited first' do
    arrive(model::Content::Unsupported.new(reason: 'undecryptable'))
    edit('quero um orçamento')

    arrive(model::Content::Text.new(body: 'quero saber o preço'))

    expect(ran(on_edit)).to eq(1)
  end
end
