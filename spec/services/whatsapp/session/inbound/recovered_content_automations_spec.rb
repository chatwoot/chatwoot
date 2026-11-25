require 'rails_helper'

# A message the backend could not decrypt in time is stored as a placeholder with no content, and the
# message itself arrives later under the same id and is written over that row. `message_created` fired
# for the placeholder, so a rule filtered on the message content never saw the body that finally
# arrived (fazer-ai/chatwoot#491).
#
# Driven through the session dispatcher with the jobs drained, rather than by calling the listener,
# because what is under test is which rules run across the two arrivals: the evaluation happens in
# `EventDispatcherJob`, the order between the arrival's job and the recovery's is not guaranteed, and a
# listener called directly would agree with any of them.
RSpec.describe 'automations on the content that arrives after its own placeholder' do # rubocop:disable RSpec/DescribeClass
  include ActiveJob::TestHelper

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:account) { inbox.account }
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }

  let(:model) { Whatsapp::Session::Model }
  let(:sender) { model::Party.new(phone: '5541999990000', lid: '182736451928374', push_name: 'Ana Souza') }
  let(:chat) { model::Address.phone('5541999990000') }
  let(:placeholder) { model::Content::Unsupported.new(reason: 'undecryptable') }
  let(:recovered) { model::Content::Text.new(body: 'Quero um orçamento') }
  let(:inbound) do
    model::InboundMessage.new(
      id: '3EB0RECOVER01', chat: chat, sender: sender, from_me: false,
      timestamp: 1_755_440_000_123, content: placeholder
    )
  end

  let!(:on_content) { rule('R_CONTEUDO', [condition('content', 'contains', ['orçamento'])]) }
  let!(:on_anything) { rule('R_QUALQUER', [condition('inbox_id', 'equal_to', [inbox.id])]) }
  let!(:on_other_content) { rule('R_OUTRO', [condition('content', 'contains', ['cancelar'])]) }

  before do
    allow(channel).to receive(:provider_service).and_return(backend)
    # The one job in the drained queue that reaches the connector: from the third delivery of a chat on
    # it asks for the contact's picture, and there is no connector behind this channel. Nothing here
    # measures avatars.
    allow(Whatsapp::Session::UpdateContactAvatarJob).to receive(:perform_later)
  end

  def condition(key, operator, values)
    { 'attribute_key' => key, 'filter_operator' => operator, 'values' => values, 'query_operator' => nil }
  end

  def rule(name, conditions)
    create(:automation_rule, account: account, name: name, event_name: 'message_created',
                             conditions: conditions,
                             actions: [{ 'action_name' => 'send_message', 'action_params' => [name] }])
  end

  # The row every execution of a rule leaves behind: `ActionService#send_message` stamps the rule id on
  # the message it sends, so the count is the number of times that rule ran.
  #
  # `#>>'{}'` first, as `Message.hide_removed_reactions` does: `content_attributes` is a json column
  # written through `store coder: JSON`, so it holds a JSON string and a plain `->>` answers NULL for
  # every row, which counts every rule as never run.
  def ran(automation_rule)
    account.messages.where("((content_attributes#>>'{}')::jsonb)->>'automation_rule_id' = ?", automation_rule.id.to_s).count
  end

  def deliver(content)
    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageReceived.new(message: inbound.with(content: content)))
    )
  end

  def arrive_and_settle(content)
    deliver(content)
    perform_enqueued_jobs
  end

  # Every recovery announcement that goes out from here on, in order. Installed before the deliveries
  # it is about, because it wraps the dispatcher rather than reading anything back.
  def recoveries_announced
    seen = []
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, timestamp, data|
      seen << data[:message].try(:source_id) if name == Events::Types::MESSAGE_RECOVERED
      original.call(name, timestamp, data)
    end
    seen
  end

  # The window has to outlast the recovery it is there to remember. WhatsApp re-encrypts when the
  # sender's phone comes back online, so hours are ordinary and a day is not unusual; a window measured
  # in minutes would be a rule running twice on the message it was supposed to protect.
  it 'remembers a rule execution for longer than a recovery takes' do
    expect(AutomationRuleListener::RULE_RUN_CLAIM_EXPIRY).to be >= 7.days
  end

  it 'runs a rule filtered on content when the content finally arrives' do
    arrive_and_settle(placeholder)
    expect(ran(on_content)).to eq(0)

    arrive_and_settle(recovered)

    expect(ran(on_content)).to eq(1)
    expect(inbox.conversations.last.labels).to be_empty.or include('orcamento')
  end

  it 'leaves a rule that does not filter on content at the one run the placeholder already gave it' do
    arrive_and_settle(placeholder)
    expect(ran(on_anything)).to eq(1)

    arrive_and_settle(recovered)

    expect(ran(on_anything)).to eq(1)
  end

  it 'evaluates the condition against the recovered body instead of firing every content rule' do
    arrive_and_settle(placeholder)
    arrive_and_settle(recovered)

    expect(ran(on_other_content)).to eq(0)
  end

  # Both evaluations run as jobs and nothing orders them, so the recovery can be the first thing that
  # ever evaluates this message. Whichever runs first must be the one that runs each rule.
  it 'runs each rule once when the recovery is evaluated before the arrival' do
    deliver(placeholder)
    deliver(recovered)

    perform_enqueued_jobs

    expect(ran(on_content)).to eq(1)
    expect(ran(on_anything)).to eq(1)
    expect(ran(on_other_content)).to eq(0)
  end

  it 'runs nothing again when the connector redelivers the recovery' do
    arrive_and_settle(placeholder)
    arrive_and_settle(recovered)

    arrive_and_settle(recovered)

    expect(ran(on_content)).to eq(1)
    expect(ran(on_anything)).to eq(1)
  end

  # The claim is per rule and per message, so the next message pays for none of it.
  it 'runs the same rule again for the next message that matches it' do
    arrive_and_settle(placeholder)
    arrive_and_settle(recovered)

    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageReceived.new(message: inbound.with(id: '3EB0PLAIN01', content: recovered)))
    )
    perform_enqueued_jobs

    expect(ran(on_content)).to eq(2)
    expect(ran(on_anything)).to eq(2)
  end

  # Everything except the automations already ran the arrival. Re-firing `message_created` for the
  # recovery would reach all of them again: the webhook of an integration that counts messages, the
  # notification, the bot.
  it 'does not dispatch a second message_created for the same message' do
    dispatched = []
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, timestamp, data|
      dispatched << [name, data[:message].try(:source_id)]
      original.call(name, timestamp, data)
    end

    arrive_and_settle(placeholder)
    arrive_and_settle(recovered)

    expect(dispatched.count([Events::Types::MESSAGE_CREATED, '3EB0RECOVER01'])).to eq(1)
    expect(dispatched.count([Events::Types::MESSAGE_RECOVERED, '3EB0RECOVER01'])).to eq(1)
  end

  # A failure between the content write and the dispatch loses the automations for good: the redelivery
  # finds the row already written and comes back as a duplicate. So the dispatch goes before the chat
  # list refresh, which is the one of the two that a later event repairs on its own.
  it 'dispatches the recovery even when refreshing the chat list fails' do
    arrive_and_settle(placeholder)
    allow(Whatsapp::Session::Inbound::ChatList).to receive(:refresh).and_raise('the chat list is away')

    expect { deliver(recovered) }.to raise_error('the chat list is away')
    perform_enqueued_jobs

    expect(ran(on_content)).to eq(1)
  end

  # Queueing the bytes is the other thing that happens after the content is saved, and the redelivery
  # queues them again on its own. The announcement has no second chance, so it cannot sit behind this.
  it 'dispatches the recovery even when queueing the media fetch fails' do
    arrive_and_settle(placeholder)
    allow(Whatsapp::Session::Inbound::MessageWriter).to receive(:fetch_media_for).and_raise('the queue is away')

    expect { deliver(recovered) }.to raise_error('the queue is away')
    perform_enqueued_jobs

    expect(ran(on_content)).to eq(1)
  end

  # And the one failure that has no second chance today: the announcement's own enqueue. The content is
  # committed by then, so the redelivery finds the row already written, comes back through the duplicate
  # path and announces nothing -- the content automations of that one message are missed for good (#646).
  it 'announces the recovery on the redelivery when the announcement itself failed to enqueue' do
    arrive_and_settle(placeholder)

    refusing = true
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, timestamp, data|
      raise 'the job transport is away' if refusing && name == Events::Types::MESSAGE_RECOVERED

      original.call(name, timestamp, data)
    end

    expect { deliver(recovered) }.to raise_error('the job transport is away')
    perform_enqueued_jobs

    # The row is already right: the content is committed and the bubble the agent sees is the message.
    # Only the announcement was lost, which is why nothing about the row says anything is owed.
    stored = inbox.messages.find_by(source_id: '3EB0RECOVER01')
    expect(stored.content).to eq('Quero um orçamento')
    expect(stored.content_attributes).not_to include('is_unsupported', 'unsupported_reason')
    expect(ran(on_content)).to eq(0)

    refusing = false
    arrive_and_settle(recovered)

    expect(ran(on_content)).to eq(1)
    expect(ran(on_anything)).to eq(1)
    expect(ran(on_other_content)).to eq(0)
  end

  # What the row owes is written by the recovery and by nothing else. The placeholder must not carry it:
  # it is not a row that was recovered, and a redelivery of one announces nothing.
  it 'marks the row as recovered only when the content is written, never on the arrival' do
    arrive_and_settle(placeholder)
    expect(inbox.messages.find_by(source_id: '3EB0RECOVER01').content_attributes)
      .not_to have_key(Whatsapp::Session::Inbound::MessageWriter::RECOVERY_OWED)

    # And an announcement that went out pays the debt off, so nothing is owed once it is enqueued.
    arrive_and_settle(recovered)

    expect(inbox.messages.find_by(source_id: '3EB0RECOVER01').content_attributes)
      .not_to have_key(Whatsapp::Session::Inbound::MessageWriter::RECOVERY_OWED)
  end

  # And the redelivery of a placeholder that is still waiting announces nothing: there is no recovery
  # to owe an announcement for, and running the rules again would answer the contact twice for an
  # arrival they already answered.
  it 'announces nothing when a placeholder that was never recovered is delivered again' do
    dispatched = recoveries_announced

    arrive_and_settle(placeholder)
    arrive_and_settle(placeholder)

    expect(dispatched.count).to eq(0)
    expect(ran(on_anything)).to eq(1)
    expect(inbox.messages.find_by(source_id: '3EB0RECOVER01').content_attributes).to include('unsupported_reason' => 'undecryptable')
  end

  # An ordinary message pays nothing for any of this: it was never a placeholder, so it is never marked
  # and its redelivery announces nothing.
  it 'leaves an ordinary message unmarked and unannounced' do
    dispatched = recoveries_announced

    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageReceived.new(message: inbound.with(id: '3EB0PLAIN01', content: recovered)))
    )
    perform_enqueued_jobs
    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageReceived.new(message: inbound.with(id: '3EB0PLAIN01', content: recovered)))
    )
    perform_enqueued_jobs

    expect(dispatched.count).to eq(0)
    expect(inbox.messages.find_by(source_id: '3EB0PLAIN01').content_attributes.keys)
      .to match_array(%w[external_created_at external_author])
    expect(ran(on_content)).to eq(1)
  end

  # A redelivery of a row that owes nothing announces nothing, and that is what keeps the rules from
  # being re-evaluated against a body they were never asked about.
  it 'announces once and stops, because the debt is paid when the announcement is enqueued' do
    dispatched = recoveries_announced

    arrive_and_settle(placeholder)
    arrive_and_settle(recovered)
    arrive_and_settle(recovered)
    arrive_and_settle(recovered)

    expect(dispatched.count).to eq(1)
    expect(ran(on_content)).to eq(1)
    expect(ran(on_anything)).to eq(1)
    expect(ran(on_other_content)).to eq(0)
  end

  # And the fence on the other side: a write that failed is not a recovery. Announcing before the
  # content is committed would need no mark at all and would pass every example above, while telling
  # the automations about a body the row does not have.
  it 'announces nothing when the content write itself fails' do
    dispatched = recoveries_announced
    arrive_and_settle(placeholder)
    allow_any_instance_of(Whatsapp::Session::Inbound::MessageWriter) # rubocop:disable RSpec/AnyInstance
      .to receive(:reconcile).and_raise('the row would not save')

    expect { deliver(recovered) }.to raise_error('the row would not save')
    perform_enqueued_jobs

    expect(dispatched.count).to eq(0)
    stored = inbox.messages.find_by(source_id: '3EB0RECOVER01')
    expect(stored.content).to be_nil
    expect(stored.content_attributes).to include('unsupported_reason' => 'undecryptable')
    expect(stored.content_attributes).not_to have_key(Whatsapp::Session::Inbound::MessageWriter::RECOVERY_OWED)
    expect(ran(on_content)).to eq(0)
  end

  # The announcement goes before the bytes on the redelivery too, and for the same reason it does on the
  # recovery itself: a media fetch that will not queue must not be what keeps the automations waiting
  # for the next delivery, which may not come.
  it 'announces the recovery on the redelivery even when queueing the media fetch fails' do
    dispatched = recoveries_announced
    arrive_and_settle(placeholder)

    refusing = true
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, timestamp, data|
      dispatched << data[:message].try(:source_id) if name == Events::Types::MESSAGE_RECOVERED
      raise 'the job transport is away' if refusing && name == Events::Types::MESSAGE_RECOVERED

      original.call(name, timestamp, data)
    end
    expect { deliver(recovered) }.to raise_error('the job transport is away')
    perform_enqueued_jobs
    refusing = false

    allow(Whatsapp::Session::Inbound::MessageWriter).to receive(:fetch_media_for).and_raise('the queue is away')
    expect { deliver(recovered) }.to raise_error('the queue is away')
    perform_enqueued_jobs

    expect(ran(on_content)).to eq(1)
  end

  # The debt is cleared after the announcement is enqueued and never before it. Cleared first, the
  # redelivery is indistinguishable from having marked nothing at all: a dispatch that fails with the
  # row already paid off loses the automations exactly the way the defect did, and the delivery after
  # it has nothing left to tell it anything is owed.
  it 'keeps the debt when the redelivery cannot enqueue the announcement either' do
    arrive_and_settle(placeholder)

    refusing = true
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, timestamp, data|
      raise 'the job transport is away' if refusing && name == Events::Types::MESSAGE_RECOVERED

      original.call(name, timestamp, data)
    end

    expect { deliver(recovered) }.to raise_error('the job transport is away')
    perform_enqueued_jobs
    expect { deliver(recovered) }.to raise_error('the job transport is away')
    perform_enqueued_jobs
    expect(ran(on_content)).to eq(0)

    refusing = false
    arrive_and_settle(recovered)

    expect(ran(on_content)).to eq(1)
    expect(inbox.messages.find_by(source_id: '3EB0RECOVER01').content_attributes)
      .not_to have_key(Whatsapp::Session::Inbound::MessageWriter::RECOVERY_OWED)
  end

  # Paying the debt is bookkeeping, and bookkeeping is not news. `update!` here would dispatch
  # MESSAGE_UPDATED, which the agent bot and the webhook listeners forward without looking at what
  # changed: every recovery would deliver a second update to everyone subscribed, which is the doubled
  # external action this design exists to avoid.
  it 'pays the debt without publishing another update' do
    updates = []
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, timestamp, data|
      updates << data[:message].try(:source_id) if name == Events::Types::MESSAGE_UPDATED
      original.call(name, timestamp, data)
    end

    arrive_and_settle(placeholder)
    before_recovery = updates.count('3EB0RECOVER01')
    arrive_and_settle(recovered)

    expect(updates.count('3EB0RECOVER01') - before_recovery).to eq(1)
  end

  # And the copy written back is read after the lock is held. `content_attributes` is one JSON hash, so
  # a revoke, an edit or a media failure landing between the content write and the settlement is a
  # change that a hash read beforehand would write away.
  it 'does not write away a change that landed while the announcement was going out' do
    arrive_and_settle(placeholder)

    # The row is changed by somebody else in the window this settlement spans.
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_wrap_original do |original, name, timestamp, data|
      if name == Events::Types::MESSAGE_RECOVERED
        row = Message.find_by(source_id: '3EB0RECOVER01')
        row.update_columns(content_attributes: row.content_attributes.merge('deleted_by_contact' => true)) # rubocop:disable Rails/SkipsModelValidations
      end
      original.call(name, timestamp, data)
    end

    arrive_and_settle(recovered)

    stored = inbox.messages.find_by(source_id: '3EB0RECOVER01')
    expect(stored.content_attributes).to include('deleted_by_contact' => true)
    expect(stored.content_attributes).not_to have_key(Whatsapp::Session::Inbound::MessageWriter::RECOVERY_OWED)
  end

  # Why the debt is cleared rather than kept, stated as the case keeping it would open. A row that was
  # recovered and announced can still be edited, and a connector redelivery can arrive after that. An
  # announcement then would offer the rules a body that neither the arrival nor the recovery ever
  # carried, and a rule that matched neither of those has no claim to stand down on: it would answer
  # the contact for a message nobody sent twice.
  it 'does not run a rule that matches only what an edit left behind' do
    dispatched = recoveries_announced
    arrive_and_settle(placeholder)
    arrive_and_settle(recovered)
    expect(ran(on_content)).to eq(1)
    expect(ran(on_other_content)).to eq(0)

    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(
                 model::Events::MessageEdited.new(
                   chat: chat, sender: sender, message_id: '3EB0RECOVER01',
                   content: model::Content::Text.new(body: 'quero cancelar'), timestamp: 1_755_450_000_123
                 )
               )
    )
    perform_enqueued_jobs

    arrive_and_settle(recovered)

    expect(dispatched.count).to eq(1)
    expect(ran(on_other_content)).to eq(0)
    expect(ran(on_content)).to eq(1)
    expect(inbox.messages.find_by(source_id: '3EB0RECOVER01').content).to eq('quero cancelar')
  end

  # Redis taking the key and the answer never arriving looks the same from here as a rule that already ran.
  # Treated as the claim it may well have written, and released, so the retry acts as it does today.
  it 'frees a claim whose acquisition could not be read back' do
    write = Redis::Alfred.method(:set)
    allow(Redis::Alfred).to receive(:set) do |key, *args, **options|
      written = write.call(key, *args, **options)
      raise 'the answer was lost' if key.include?('AUTOMATION_RULE_MESSAGE_RUN')

      written
    end

    deliver(placeholder)
    expect { perform_enqueued_jobs }.to raise_error('the answer was lost')

    allow(Redis::Alfred).to receive(:set).and_call_original
    Rails.configuration.dispatcher.dispatch(
      Events::Types::MESSAGE_CREATED, Time.zone.now, message: inbox.messages.find_by(source_id: '3EB0RECOVER01')
    )
    perform_enqueued_jobs

    expect(ran(on_anything)).to eq(1)
  end

  # The same lost answer, with the key already held by the arrival's own execution. Releasing that one
  # would hand the retry a rule that already answered the contact.
  it 'leaves a claim an earlier execution owns when its own acquisition could not be read back' do
    arrive_and_settle(placeholder)
    expect(ran(on_anything)).to eq(1)

    # Only the claim of the rule the arrival already ran: that key is the one a release must not touch.
    write = Redis::Alfred.method(:set)
    allow(Redis::Alfred).to receive(:set) do |key, *args, **options|
      written = write.call(key, *args, **options)
      raise 'the answer was lost' if key.include?("AUTOMATION_RULE_MESSAGE_RUN::#{on_anything.id}::")

      written
    end

    deliver(recovered)
    expect { perform_enqueued_jobs }.to raise_error('the answer was lost')
    allow(Redis::Alfred).to receive(:set).and_call_original
    Rails.configuration.dispatcher.dispatch(
      Events::Types::MESSAGE_RECOVERED, Time.zone.now, message: inbox.messages.find_by(source_id: '3EB0RECOVER01')
    )
    perform_enqueued_jobs

    expect(ran(on_anything)).to eq(1)
    expect(ran(on_content)).to eq(1)
  end

  # A placeholder stored before this was deployed ran its rules with no claim written, so evaluating them
  # again would run the ones that do not filter on content a second time. Upgrading must not answer a
  # message from before it twice; missing the content is what that row had already settled for.
  it 'runs nothing for a placeholder whose arrival was never tracked' do
    arrive_and_settle(placeholder)
    stored = inbox.messages.find_by(source_id: '3EB0RECOVER01')
    Redis::Alfred.delete(format(Redis::RedisKeys::AUTOMATION_MESSAGE_ARRIVAL_TRACKED, message_id: stored.id))
    Redis::Alfred.delete(format(Redis::RedisKeys::AUTOMATION_RULE_MESSAGE_RUN, rule_id: on_anything.id, message_id: stored.id))

    arrive_and_settle(recovered)

    expect(stored.reload.content).to eq('Quero um orçamento')
    expect(ran(on_anything)).to eq(1)
    expect(ran(on_content)).to eq(0)
  end

  # The history import writes its rows with every callback suppressed, so nothing ran when they landed.
  # The content of an archived message is not a message arriving, and rules answering traffic from weeks
  # ago is the one thing the import is careful never to do.
  it 'runs nothing for a placeholder the history import wrote' do
    contact = create(:contact, account: account, phone_number: '+5541999990000')
    contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox, source_id: '5541999990000')
    conversation = create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
    Import::SilentWrite.wrap do
      Whatsapp::Session::Inbound::MessageWriter.new(
        conversation: conversation, inbound: inbound, sender: contact, imported: true
      ).perform
    end
    perform_enqueued_jobs

    arrive_and_settle(recovered)

    expect(inbox.messages.find_by(source_id: '3EB0RECOVER01').content).to eq('Quero um orçamento')
    expect(ran(on_content)).to eq(0)
    expect(ran(on_anything)).to eq(0)
  end

  # The claim is there to stop a second run, not to spend a rule's only chance on an attempt that never
  # acted: a rule whose execution raised (the database gone while a delayed rule is being scheduled) has
  # to be free again for the retry, which is what happens today.
  it 'frees a rule whose execution raised, so the retry still runs it' do
    attempts = 0
    build_action_service = AutomationRules::ActionService.method(:new)
    allow(AutomationRules::ActionService).to receive(:new) do |*args|
      attempts += 1
      raise 'the database went away' if attempts == 1

      build_action_service.call(*args)
    end

    deliver(placeholder)
    expect { perform_enqueued_jobs }.to raise_error('the database went away')

    # What Sidekiq does with the event whose job raised, which nothing else here stands in for.
    Rails.configuration.dispatcher.dispatch(
      Events::Types::MESSAGE_CREATED, Time.zone.now, message: inbox.messages.find_by(source_id: '3EB0RECOVER01')
    )
    perform_enqueued_jobs

    expect(ran(on_anything)).to eq(1)
  end

  # A placeholder that is never recovered is not held back: the arrival is what the agent sees, and a
  # content rule has nothing to match.
  it 'keeps the placeholder arrival immediate' do
    arrive_and_settle(placeholder)

    expect(ran(on_anything)).to eq(1)
    expect(ran(on_content)).to eq(0)
    expect(inbox.messages.find_by(source_id: '3EB0RECOVER01').content_attributes['unsupported_reason']).to eq('undecryptable')
  end
end
