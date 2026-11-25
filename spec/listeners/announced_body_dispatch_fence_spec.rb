require 'rails_helper'

# `AutomationRuleListener` evaluates a body-scoped event only while the row still shows the body the
# announcement named, and it reads an announcement carrying no `content` as one that named none: that is
# what the events already queued when this shipped look like, and discarding those would lose the
# automations of every message in flight during a deploy (fazer-ai/chatwoot#660, #661).
#
# Which means the silence has to be unambiguous. A dispatch site added later that forgets the key would
# be read as "named no body" and would quietly stop being checked, and nothing about the row or the
# queue would say so. This is the only thing that can tell the two apart, so it is a fence over the
# source rather than a test of behaviour: the question is asked in more than one place and the answer
# has to be the same in all of them.
RSpec.describe 'every announcement of a body-scoped event names its body' do # rubocop:disable RSpec/DescribeClass
  let(:roots) { %w[app lib enterprise] }
  let(:events) { %w[MESSAGE_RECOVERED MESSAGE_EDITED] }

  # The dispatch call as written, however many lines it takes: from `dispatch(` to the paren that closes
  # it. Counting parens rather than reading to the end of the line, because both of these sites wrap.
  def dispatch_calls(source)
    calls = []
    offset = 0
    while (start = source.index('.dispatch(', offset))
      open = source.index('(', start)
      depth = 0
      finish = open
      while finish < source.length
        depth += 1 if source[finish] == '('
        depth -= 1 if source[finish] == ')'
        break if depth.zero?

        finish += 1
      end
      calls << source[start..finish]
      offset = finish + 1
    end
    calls
  end

  def ruby_files
    roots.flat_map { |root| Dir.glob(Rails.root.join(root, '**/*.rb')) }
  end

  it 'passes content: at every dispatch site of one' do
    missing = ruby_files.flat_map do |path|
      dispatch_calls(File.read(path)).filter_map do |call|
        next unless events.any? { |event| call.include?(event) }
        next if call.include?('content:')

        "#{Pathname.new(path).relative_path_from(Rails.root)}: #{call.squish}"
      end
    end

    expect(missing).to be_empty, "these dispatches name no body, so the listener would stop checking them:\n#{missing.join("\n")}"
  end

  # The fence is only worth anything while it has something to guard, and a typo in the constant names
  # above would leave it scanning for nothing and passing.
  #
  # Three since #666: the session handler announcing a recovery, `Message#send_edited_event`, and
  # `Message#send_recovered_event`, which the write-back after a refused edit calls when the body it
  # restored is the one a recovery brought. Raising this number is not a formality -- do it only with
  # the new site read, because the assertion above is what says it names a body.
  it 'is looking at the three sites that exist' do
    found = ruby_files.sum { |path| dispatch_calls(File.read(path)).count { |call| events.any? { |event| call.include?(event) } } }

    expect(found).to eq(3)
  end

  # The other half of the same question, and the only one that cannot be driven through a dispatcher:
  # no site can produce this payload any more, which is exactly what makes it worth pinning. It is the
  # shape of every one of these already in the queue and in the retry set while this deploys, and
  # reading their silence as an empty body would discard the automations of every message in flight.
  describe 'an announcement from before this shipped, carrying no content at all' do
    let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
    let(:inbox) { channel.inbox }
    let(:account) { inbox.account }
    let(:conversation) { create(:conversation, inbox: inbox, account: account) }
    let!(:message) { create(:message, conversation: conversation, account: account, inbox: inbox, content: 'quero um orçamento') }
    let!(:on_edit) do
      create(:automation_rule, account: account, name: 'ED_ORC', event_name: 'message_edited',
                               conditions: [{ 'attribute_key' => 'content', 'filter_operator' => 'contains',
                                              'values' => ['orçamento'], 'query_operator' => nil }],
                               actions: [{ 'action_name' => 'send_message', 'action_params' => ['ED_ORC'] }])
    end

    it 'is evaluated rather than discarded' do
      event = Events::Base.new(Events::Types::MESSAGE_EDITED, Time.zone.now, message: message)

      AutomationRuleListener.instance.message_edited(event)

      ran = account.messages.where("((content_attributes#>>'{}')::jsonb)->>'automation_rule_id' = ?", on_edit.id.to_s).count
      expect(ran).to eq(1)
    end
  end

  # That an arrival is outside all of this is a product decision (fazer-ai/chatwoot#648): an edit never
  # re-opens `message_created`. Nothing dispatched today names a body on an arrival, so the decision is
  # invisible in behaviour -- which is why it is pinned here, by handing one a body the row does not have
  # and asking for the rules anyway.
  describe 'an arrival that somehow names a body' do
    let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
    let(:inbox) { channel.inbox }
    let(:account) { inbox.account }
    let(:conversation) { create(:conversation, inbox: inbox, account: account) }
    let!(:message) { create(:message, conversation: conversation, account: account, inbox: inbox, content: 'quero um orçamento') }
    let!(:on_create) do
      create(:automation_rule, account: account, name: 'CR_ORC', event_name: 'message_created',
                               conditions: [{ 'attribute_key' => 'content', 'filter_operator' => 'contains',
                                              'values' => ['orçamento'], 'query_operator' => nil }],
                               actions: [{ 'action_name' => 'send_message', 'action_params' => ['CR_ORC'] }])
    end

    it 'is evaluated against the row all the same' do
      event = Events::Base.new(Events::Types::MESSAGE_CREATED, Time.zone.now, message: message, content: 'um corpo que a linha não tem')

      AutomationRuleListener.instance.message_created(event)

      ran = account.messages.where("((content_attributes#>>'{}')::jsonb)->>'automation_rule_id' = ?", on_create.id.to_s).count
      expect(ran).to eq(1)
    end
  end
end
