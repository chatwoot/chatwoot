require 'rails_helper'

# An agent's edit is written before the channel has taken it and written back when the channel refuses
# (#648). A recovery announcement queued for the same row is evaluated against the row when the job runs,
# finds the optimistic body there and stands down (#661) -- and nothing asks again once the refusal puts
# the recovered body back. The rules the recovery exists to re-ask then never run for the body the contact
# actually has (#666).
#
# Driven through the real session pipeline rather than a hand-written row: what makes a row recoverable,
# and what it carries afterwards, is the writer's own business, and a fixture that writes those keys by
# hand would pass while the writer wrote something else.
RSpec.describe 'a recovery caught inside a refused optimistic edit', type: :request do
  include ActiveJob::TestHelper

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:account) { inbox.account }
  let(:agent) { create(:user, account: account, role: :agent) }

  let(:model) { Whatsapp::Session::Model }
  let(:sender) { model::Party.new(phone: '5541999990666', lid: '182736451920666', push_name: 'Ana Souza') }
  let(:placeholder) { model::Content::Unsupported.new(reason: 'undecryptable') }
  let(:inbound) do
    model::InboundMessage.new(
      id: '3EB0666', chat: model::Address.phone('5541999990666'), sender: sender, from_me: true,
      timestamp: 1_755_440_000_666, content: placeholder
    )
  end

  let!(:on_orcamento) { arrival_rule('CR_ORC', 'orçamento') }
  let!(:on_desconto) { arrival_rule('CR_DESCONTO', 'desconto') }

  # The ordinary account has one of these, and it is what makes a finished claim different from an
  # in-flight one: it does not filter on content, so it matches while the row is still a placeholder,
  # runs there, and its claim then sits for thirty days. Read as "somebody is still working on this", it
  # would keep the arrival record standing for every such account, for good.
  let!(:on_anything) do
    create(:automation_rule, account: account, name: 'CR_QUALQUER', event_name: 'message_created',
                             conditions: [{ 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to',
                                            'values' => [inbox.id], 'query_operator' => nil }],
                             actions: [{ 'action_name' => 'send_message', 'action_params' => ['CR_QUALQUER'] }])
  end

  before do
    allow(channel).to receive(:provider_service).and_return(Whatsapp::Session::Backends::Fake.new(channel))
    allow(Whatsapp::Session::UpdateContactAvatarJob).to receive(:perform_later)
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original
    create(:inbox_member, inbox: inbox, user: agent)
  end

  def arrival_rule(name, word)
    create(:automation_rule, account: account, name: name, event_name: 'message_created',
                             conditions: [{ 'attribute_key' => 'content', 'filter_operator' => 'contains',
                                            'values' => [word], 'query_operator' => nil }],
                             actions: [{ 'action_name' => 'send_message', 'action_params' => [name] }])
  end

  # `ActionService#send_message` stamps the rule id on what it sends, so this counts executions. `#>>'{}'`
  # first because `content_attributes` is a json column written through `store coder: JSON`.
  def ran(rule)
    account.messages.where("((content_attributes#>>'{}')::jsonb)->>'automation_rule_id' = ?", rule.id.to_s).count
  end

  # Everything but the avatar fetch, which would go out to gravatar from inside the example.
  def drain
    perform_enqueued_jobs(except: Avatar::AvatarFromUrlJob)
  end

  def deliver(content)
    Whatsapp::Session::Inbound::Dispatcher.dispatch(
      channel, model::Event.build(model::Events::MessageReceived.new(message: inbound.with(content: content)))
    )
  end

  def stored
    account.messages.find_by!(source_id: inbound.id)
  end

  def edit(content)
    row = stored
    patch edit_content_api_v1_account_conversation_message_url(
      account_id: account.id, conversation_id: row.conversation.display_id, id: row.id
    ), params: { content: content }, headers: agent.create_new_auth_token, as: :json
  end

  # The channel refuses, and the queued work runs inside the window the optimistic write is open: that is
  # the whole of the race, and draining from here is what puts the recovery's evaluation in it.
  def refuse_the_edit
    allow_any_instance_of(Channel::Whatsapp).to receive(:edit_message) do # rubocop:disable RSpec/AnyInstance
      drain
      raise StandardError, 'channel refused'
    end
  end

  # The row is stored unreadable and its arrival is evaluated against no body, then the message itself
  # arrives under the same id and fills it in. The recovery announcement is left in the queue.
  def recover_into(body)
    deliver(placeholder)
    drain
    deliver(model::Content::Text.new(body: body))
  end

  it 'asks the arrival rules about the recovered body the refusal put back' do
    recover_into('quero um orçamento')
    refuse_the_edit

    edit('desconto de 30%')
    drain

    expect(stored.content).to eq('quero um orçamento')
    expect(ran(on_desconto)).to eq(0)
    expect(ran(on_orcamento)).to eq(1)
  end

  # The body a refusal puts back is the one the row had before the optimistic write, which stops being the
  # recovered body as soon as an edit has been accepted. Announcing that one as recovered would have the
  # arrival rules answer about a body no recovery ever carried, which is the whole of #661.
  it 'leaves the arrival rules alone when the refusal puts an accepted edit back' do
    recover_into('quero saber o preço')
    drain

    accepted = true
    allow_any_instance_of(Channel::Whatsapp).to receive(:edit_message) do # rubocop:disable RSpec/AnyInstance
      next true if accepted

      drain
      raise StandardError, 'channel refused'
    end

    edit('desconto de 30%')
    drain
    accepted = false
    edit('quero um orçamento')
    drain

    expect(stored.content).to eq('desconto de 30%')
    expect(ran(on_desconto)).to eq(0)
  end

  # Asserted on the announcement and not only on the rule counts. `AutomationRuleListener#message_recovered`
  # already stands down for a row whose arrival it never tracked, so a recovery announced here would run
  # nothing and no counter would move -- and a fence that only counts rules would be resting on a guard in
  # another class instead of on this one. Measured: dropping the digest check leaves every count identical.
  it 'announces no recovery for a row no recovery ever filled in' do
    deliver(model::Content::Text.new(body: 'quero um orçamento'))
    drain
    before_count = ran(on_orcamento)
    refuse_the_edit

    edit('desconto de 30%')
    drain

    expect(stored.content).to eq('quero um orçamento')
    expect(ran(on_orcamento)).to eq(before_count)
    expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
      .with(Events::Types::MESSAGE_RECOVERED, anything, anything)
  end

  # The arrival record lives for thirty days, so a recovery answered weeks ago would still look like one
  # waiting for an answer. Re-opening the arrival rules there asks whatever rules the account has by then,
  # not the ones the recovery was about: an auto-reply answering a message from weeks back because an
  # agent's edit failed to send. A refused edit carries no news about the message, and must not be read
  # as a second arrival.
  it 'does not re-open the arrival rules for a recovery that was already answered' do
    recover_into('quero um orçamento')
    drain
    expect(ran(on_orcamento)).to eq(1)

    # It ran at the arrival, against the placeholder, and its claim has been sitting there since.
    expect(ran(on_anything)).to eq(1)

    added_later = arrival_rule('CR_NOVA', 'orçamento')
    refuse_the_edit

    edit('desconto de 30%')
    drain

    expect(stored.content).to eq('quero um orçamento')
    expect(ran(added_later)).to eq(0)
  end

  # The two findings of the second review round, stated as the property that makes both impossible: the
  # record of the arrival ends when this execution finished the question, decided inside the lock where
  # the decision was made, and never from the row as it reads afterwards. The body is being written to
  # throughout this window, so a second look is a different question wearing the same words.
  describe 'the record that keeps a recovery answerable' do
    def arrival_recorded?(message)
      Redis::Alfred.exists?(format(Redis::RedisKeys::AUTOMATION_MESSAGE_ARRIVAL_TRACKED, message_id: message.id))
    end

    it 'keeps the record standing when the recovery could not be evaluated' do
      recover_into('quero um orçamento')
      row = stored
      row.update!(content: 'desconto de 30%', is_edited: true)
      drain

      expect(ran(on_orcamento)).to eq(0)
      expect(arrival_recorded?(row)).to be(true)
    end

    it 'ends the record once the recovery has been evaluated' do
      recover_into('quero um orçamento')
      drain

      expect(ran(on_orcamento)).to eq(1)
      expect(arrival_recorded?(stored)).to be(false)
    end

    # An execution that finds a claim still in flight owns nothing: the execution that took it may be
    # acting right now, and ending the record here would take it out from under that one's retry if its
    # action raises. A claim left as a token rather than marked finished is exactly that state, and it is
    # what a crashed or still-running execution leaves behind.
    it 'leaves the record to an execution whose claim has not finished' do
      recover_into('quero um orçamento')
      drain
      row = stored
      expect(arrival_recorded?(row)).to be(false)

      Redis::Alfred.set(format(Redis::RedisKeys::AUTOMATION_MESSAGE_ARRIVAL_TRACKED, message_id: row.id), Time.current.to_i)
      Redis::Alfred.set(format(Redis::RedisKeys::AUTOMATION_RULE_MESSAGE_RUN, rule_id: on_orcamento.id, message_id: row.id),
                        SecureRandom.uuid)
      Rails.configuration.dispatcher.dispatch(Events::Types::MESSAGE_RECOVERED, Time.zone.now,
                                              message: row, content: 'quero um orçamento')
      drain

      expect(ran(on_orcamento)).to eq(1)
      expect(arrival_recorded?(row)).to be(true)
    end

    # Marking a claim finished rewrites it, and a rewrite is where an expiry is lost without a sound. With
    # no expiry the claims leak for ever; with a short one the rule becomes free to run again, which is
    # the opposite of what a claim is for. Neither shows up in any assertion about behaviour inside one
    # example, because both stay green for as long as an example lives.
    it 'leaves a finished claim with the window the unfinished one had' do
      recover_into('quero um orçamento')
      drain

      key = format(Redis::RedisKeys::AUTOMATION_RULE_MESSAGE_RUN, rule_id: on_orcamento.id, message_id: stored.id)

      expect(Redis::Alfred.get(key)).to eq(AutomationRuleListener::CLAIM_DONE)
      expect(Redis::Alfred.ttl(key)).to be > 29.days.to_i
    end

    # The other side of the same distinction, and the one the ordinary account hits every time: a claim
    # left by an execution that finished is not somebody at work, and reading it as one would leave the
    # record standing for good.
    it 'ends the record even though a rule ran at the arrival and still holds its claim' do
      recover_into('quero um orçamento')
      drain

      expect(ran(on_anything)).to eq(1)
      expect(arrival_recorded?(stored)).to be(false)
    end
  end

  it 'does not run a rule the recovery already ran a second time' do
    recover_into('quero um orçamento')
    drain
    expect(ran(on_orcamento)).to eq(1)
    refuse_the_edit

    edit('desconto de 30%')
    drain

    expect(ran(on_orcamento)).to eq(1)
  end
end
