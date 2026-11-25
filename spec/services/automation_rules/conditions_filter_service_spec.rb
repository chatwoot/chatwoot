require 'rails_helper'

RSpec.describe AutomationRules::ConditionsFilterService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:email_channel) { create(:channel_email, account: account) }
  let(:email_inbox) { create(:inbox, channel: email_channel, account: account) }
  let(:message) do
    create(:message, account: account, conversation: conversation, content: 'test text', inbox: conversation.inbox, message_type: :incoming)
  end
  let(:rule) { create(:automation_rule, account: account) }

  before do
    conversation = create(:conversation, account: account)
    conversation.contact.update!(phone_number: '+918484828282', email: 'test@test.com')
    create(:conversation, account: account)
    create(:conversation, account: account)
  end

  describe '#perform' do
    context 'when conditions based on filter_operator equal_to' do
      before do
        rule.conditions = [{ 'values': ['open'], 'attribute_key': 'status', 'query_operator': nil, 'filter_operator': 'equal_to' }]
        rule.save!
      end

      context 'when conditions in rule matches with object' do
        it 'will return true' do
          expect(described_class.new(rule, conversation, { changed_attributes: { status: [nil, 'open'] } }).perform).to be(true)
        end
      end

      context 'when conditions in rule does not match with object' do
        it 'will return false' do
          conversation.update!(status: 'resolved')
          expect(described_class.new(rule, conversation, { changed_attributes: { status: %w[open resolved] } }).perform).to be(false)
        end
      end
    end

    # These are evaluated against the event's `changed_attributes` rather than against the
    # record, so an event that touched something else has nothing under the filter's key.
    context 'when conditions based on filter_operator attribute_changed' do
      def two_conditions(operator)
        [
          { 'values': { 'from': [nil], 'to': ['1'] }, 'attribute_key': 'assignee_id', 'query_operator': operator,
            'filter_operator': 'attribute_changed' },
          { 'values': { 'from': ['open'], 'to': ['resolved'] }, 'attribute_key': 'status', 'query_operator': nil,
            'filter_operator': 'attribute_changed' }
        ]
      end

      # The NoMethodError this used to raise was swallowed by `perform`'s rescue, so the only
      # sign of it was a log line -- and the rule was abandoned with whatever conditions came
      # after the untouched one never evaluated.
      it 'evaluates the rule instead of abandoning it on an untouched attribute' do
        rule.update!(conditions: two_conditions('AND'))
        expect(Rails.logger).not_to receive(:error)

        described_class.new(rule, conversation, { changed_attributes: { status: %w[open resolved] } }).perform
      end

      # Answering false is what the swallowed exception already amounted to, and holding that
      # answer is the point: the fix is not allowed to make a rule fire that does not fire
      # today. Whether false is *right* for a rule whose other conditions could stand on
      # their own is #468, which this method cannot decide.
      it 'does not fire when the event never touched the attribute' do
        rule.update!(conditions: two_conditions('AND'))

        expect(described_class.new(rule, conversation, { changed_attributes: { status: %w[open resolved] } }).perform).to be(false)
      end

      it 'still fires when every attribute changed the way the filters ask for' do
        rule.update!(conditions: two_conditions('AND'))

        expect(
          described_class.new(rule, conversation, { changed_attributes: { assignee_id: [nil, '1'], status: %w[open resolved] } }).perform
        ).to be(true)
      end
    end

    context 'when conditions based on filter_operator start_with' do
      before do
        contact = conversation.contact
        contact.update!(phone_number: '+918484848484')
        rule.conditions = [
          { 'values': ['+918484'], 'attribute_key': 'phone_number', 'query_operator': 'OR', 'filter_operator': 'starts_with' },
          { 'values': ['test'], 'attribute_key': 'email', 'query_operator': nil, 'filter_operator': 'contains' }
        ]
        rule.save!
      end

      context 'when conditions in rule matches with object' do
        it 'will return true' do
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
        end
      end

      context 'when conditions in rule does not match with object' do
        it 'will return false' do
          conversation.contact.update!(phone_number: '+918585858585')
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
        end
      end
    end

    context 'when conditions check assignee presence' do
      let(:agent_bot) { create(:agent_bot, account: account) }

      before do
        conversation.update!(ai_assignee: agent_bot)
      end

      it 'treats AgentBot ownership as present' do
        rule.update!(conditions: [{ 'values': [], 'attribute_key': 'assignee_id', 'query_operator': nil, 'filter_operator': 'is_present' }])

        expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
      end

      it 'does not treat AgentBot ownership as absent' do
        rule.update!(conditions: [{ 'values': [], 'attribute_key': 'assignee_id', 'query_operator': nil, 'filter_operator': 'is_not_present' }])

        expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
      end
    end

    context 'when conditions include a Captain condition' do
      let(:captain_condition) do
        { 'values': ['the customer wants a refund'], 'attribute_key': 'captain_condition', 'query_operator': nil, 'filter_operator': 'detects' }
      end
      let(:captain_answers) { { 1 => true } }

      before do
        account.enable_features!('captain_classifier')
        allow(Captain::AutomationConditionService).to receive(:new)
          .and_return(instance_double(Captain::AutomationConditionService, perform: captain_answers))
      end

      it 'passes the rule conditions and the message to Captain' do
        rule.update!(conditions: [captain_condition])

        described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform

        expect(Captain::AutomationConditionService).to have_received(:new)
          .with(conditions: rule.conditions, conversation: conversation, message: message)
      end

      it 'does not ask Captain when another condition already rules the match out' do
        rule.update!(conditions: [
                       { 'values': ['resolved'], 'attribute_key': 'status', 'query_operator': 'AND', 'filter_operator': 'equal_to' },
                       captain_condition
                     ])

        expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
        expect(Captain::AutomationConditionService).not_to have_received(:new)
      end

      it 'does not ask Captain when another condition already decides the match' do
        rule.update!(conditions: [
                       { 'values': ['open'], 'attribute_key': 'status', 'query_operator': 'OR', 'filter_operator': 'equal_to' },
                       captain_condition
                     ])

        expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
        expect(Captain::AutomationConditionService).not_to have_received(:new)
      end

      it 'does not ask Captain about an agent reply when the rule is for customer messages' do
        message.update!(message_type: :outgoing)
        rule.update!(conditions: [
                       { 'values': ['incoming'], 'attribute_key': 'message_type', 'query_operator': 'AND', 'filter_operator': 'equal_to' },
                       captain_condition
                     ])

        expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        expect(Captain::AutomationConditionService).not_to have_received(:new)
      end

      it 'combines a detected condition with the other conditions using AND' do
        rule.update!(conditions: [
                       { 'values': ['open'], 'attribute_key': 'status', 'query_operator': 'AND', 'filter_operator': 'equal_to' },
                       captain_condition
                     ])

        expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
      end

      it 'does not match when Captain does not detect the condition' do
        rule.update!(conditions: [
                       { 'values': ['open'], 'attribute_key': 'status', 'query_operator': 'AND', 'filter_operator': 'equal_to' },
                       captain_condition
                     ])
        captain_answers[1] = false

        expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
      end

      it 'lets a detected condition satisfy an OR chain on its own' do
        rule.update!(conditions: [
                       { 'values': ['resolved'], 'attribute_key': 'status', 'query_operator': 'OR', 'filter_operator': 'equal_to' },
                       captain_condition
                     ])

        expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
      end
    end

    context 'when Captain cannot judge a Captain condition' do
      let(:endpoint) { 'https://openrouter.example/v1/systemone' }
      let(:captain_condition) do
        { 'values': ['the customer wants a refund'], 'attribute_key': 'captain_condition', 'query_operator': nil, 'filter_operator': 'detects' }
      end

      before do
        account.enable_features!('captain_classifier')
        allow(GlobalConfigService).to receive(:load).and_call_original
        allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil).and_return('https://openrouter.example')
        allow(GlobalConfigService).to receive(:load).with('CAPTAIN_OPENROUTER_API_KEY', nil).and_return('secret-key')
        stub_request(:post, endpoint).to_return(status: 200, body: { answers: { '0' => { 'noul' => 0.9 }, '1' => { 'noul' => 0.9 } } }.to_json,
                                                headers: { 'Content-Type' => 'application/json' })
      end

      it 'matches through another condition without needing Captain, even while Captain is failing' do
        stub_request(:post, endpoint).to_return(status: 500, body: 'upstream error')
        rule.update!(conditions: [
                       { 'values': ['open'], 'attribute_key': 'status', 'query_operator': 'OR', 'filter_operator': 'equal_to' },
                       captain_condition
                     ])

        expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        expect(a_request(:post, endpoint)).not_to have_been_made
      end

      it 'does not match when the rule depends on Captain and the request fails' do
        stub_request(:post, endpoint).to_return(status: 500, body: 'upstream error')
        rule.update!(conditions: [captain_condition])

        expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        expect(a_request(:post, endpoint)).to have_been_made.once
      end

      it 'does not match a private note and never sends it to Captain' do
        rule.update!(conditions: [captain_condition])
        message.update!(private: true)

        expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        expect(a_request(:post, endpoint)).not_to have_been_made
      end

      it 'still lets the other conditions of the rule decide for a private note' do
        rule.update!(conditions: [
                       { 'values': [true], 'attribute_key': 'private_note', 'query_operator': 'OR', 'filter_operator': 'equal_to' },
                       captain_condition
                     ])
        message.update!(private: true)

        expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        expect(a_request(:post, endpoint)).not_to have_been_made
      end

      it 'pauses the Captain condition when the feature is revoked, keeping the rule active' do
        rule.update!(conditions: [captain_condition])
        account.disable_features!('captain_classifier')

        expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        expect(a_request(:post, endpoint)).not_to have_been_made
        expect(rule.reload).to be_active
        expect(rule.authorization_error_count).to eq(0)
      end
    end

    context 'when conditions based on messages attributes' do
      context 'when filter_operator is equal_to' do
        before do
          rule.conditions = [
            { 'values': ['test text'], 'attribute_key': 'content', 'query_operator': 'AND', 'filter_operator': 'equal_to' },
            { 'values': ['incoming'], 'attribute_key': 'message_type', 'query_operator': nil, 'filter_operator': 'equal_to' }
          ]
          rule.save!
        end

        it 'will return true when conditions matches' do
          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        end

        it 'will return false when conditions in rule does not match' do
          message.update!(message_type: :outgoing)
          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        end
      end

      context 'when filtering private notes' do
        before do
          rule.conditions = [
            { 'values': [true], 'attribute_key': 'private_note', 'query_operator': nil, 'filter_operator': 'equal_to' }
          ]
          rule.save!
        end

        it 'will return true when the message is a private note' do
          message.update!(private: true)

          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        end

        it 'will return false when the message is not a private note' do
          message.update!(private: false)

          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        end
      end

      context 'when filtering by the message sender' do
        let(:agent) { create(:user, account: account, role: :agent) }
        let(:bot_agent) { create(:user, account: account, role: :agent) }

        before do
          rule.conditions = [
            { 'values': [bot_agent.id], 'attribute_key': 'sender_id', 'query_operator': 'AND', 'filter_operator': 'not_equal_to' },
            { 'values': ['User'], 'attribute_key': 'sender_type', 'query_operator': nil, 'filter_operator': 'equal_to' }
          ]
          rule.save!
        end

        it 'will return true when another agent sent the message' do
          message.update!(sender: agent)

          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        end

        it 'will return false when the excluded agent sent the message' do
          message.update!(sender: bot_agent)

          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        end

        # sender_id is a polymorphic id: without sender_type a contact sharing the agent's id would match.
        it 'will return false when a contact sent the message' do
          message.update!(sender: conversation.contact)

          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        end

        # `sender_id != x` is NULL, not true, for a message nobody signed. Not matching is the intended read.
        it 'will return false when the message has no sender' do
          message.update!(sender: nil)

          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        end

        it 'will return true for the agent holding the id when the rule does not pin the sender type' do
          rule.update!(conditions: [
                         { 'values': [agent.id], 'attribute_key': 'sender_id', 'query_operator': nil, 'filter_operator': 'equal_to' }
                       ])
          message.update!(sender: agent)

          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        end

        # sender_id is polymorphic and contacts number their rows independently of users, so an
        # unpinned id would otherwise be answered by whichever contact happens to hold it.
        it 'will return false for a contact holding the agent id when the rule does not pin the sender type' do
          rule.update!(conditions: [
                         { 'values': [agent.id], 'attribute_key': 'sender_id', 'query_operator': nil, 'filter_operator': 'equal_to' }
                       ])
          message.update!(sender_type: 'Contact', sender_id: agent.id)

          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        end
      end

      context 'when an account attribute shares its name with a message attribute' do
        before do
          create(:custom_attribute_definition, attribute_key: 'sender_id', account: account,
                                               attribute_model: 'conversation_attribute', attribute_display_type: 'text')
          conversation.update!(custom_attributes: { sender_id: 'crm-42' })
          rule.conditions = [
            { 'values': ['crm-42'], 'attribute_key': 'sender_id', 'query_operator': nil,
              'filter_operator': 'equal_to', 'custom_attribute_type': 'conversation_attribute' }
          ]
          rule.save!
        end

        it 'resolves the account attribute instead of the message column' do
          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        end

        # A checkbox attribute holds a boolean, and the standard sender_type key is compared downcased.
        it 'leaves a checkbox account attribute alone instead of downcasing its boolean' do
          create(:custom_attribute_definition, attribute_key: 'sender_type', account: account,
                                               attribute_model: 'conversation_attribute', attribute_display_type: 'checkbox')
          conversation.update!(custom_attributes: { sender_type: true })
          rule.update!(conditions: [
                         { 'values': [true], 'attribute_key': 'sender_type', 'query_operator': nil,
                           'filter_operator': 'equal_to', 'custom_attribute_type': 'conversation_attribute' }
                       ])

          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        end
      end

      # The dashboard offers a single-value picker for a list attribute, but the API stores every value
      # it is given, and the SQL is an IN (...): a condition with two values must match either of them.
      context 'when a custom attribute condition carries more than one value' do
        before do
          create(:custom_attribute_definition, attribute_key: 'fechamento', account: account,
                                               attribute_model: 'conversation_attribute', attribute_display_type: 'list',
                                               attribute_values: ['Atendimento iniciado', 'Parou de responder', 'Venda efetivada'])
        end

        def rule_with(operator)
          rule.update!(conditions: [
                         { 'values': ['Atendimento iniciado', 'Parou de responder'], 'attribute_key': 'fechamento',
                           'query_operator': nil, 'filter_operator': operator, 'custom_attribute_type': 'conversation_attribute' }
                       ])
          rule
        end

        def matches?(operator, value)
          conversation.update!(custom_attributes: { fechamento: value })
          described_class.new(rule_with(operator), conversation, { changed_attributes: {} }).perform
        end

        it 'matches a conversation holding the second value, not only the first' do
          expect(matches?('equal_to', 'Parou de responder')).to be(true)
          expect(matches?('equal_to', 'Atendimento iniciado')).to be(true)
          expect(matches?('equal_to', 'Venda efetivada')).to be(false)
        end

        it 'compares every value without regard to case' do
          expect(matches?('equal_to', 'PAROU DE RESPONDER')).to be(true)
        end

        it 'excludes every value on not_equal_to' do
          expect(matches?('not_equal_to', 'Parou de responder')).to be(false)
          expect(matches?('not_equal_to', 'Atendimento iniciado')).to be(false)
          expect(matches?('not_equal_to', 'Venda efetivada')).to be(true)
        end
      end

      context 'when filter_operator is on processed_message_content' do
        before do
          rule.conditions = [
            { 'values': ['help'], 'attribute_key': 'content', 'query_operator': 'AND', 'filter_operator': 'contains' },
            { 'values': ['incoming'], 'attribute_key': 'message_type', 'query_operator': nil, 'filter_operator': 'equal_to' }
          ]
          rule.save!
        end

        let(:conversation) { create(:conversation, account: account, inbox: email_inbox) }
        let(:message) do
          create(:message, account: account, conversation: conversation, content: "We will help you\n\n\n test",
                           inbox: conversation.inbox, message_type: :incoming,
                           content_attributes: { email: { text_content: { quoted: 'We will help you' } } })
        end

        it 'will return true for processed_message_content matches' do
          message
          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        end

        it 'will return false when processed_message_content does no match' do
          rule.update!(conditions: [{ 'values': ['text'], 'attribute_key': 'content', 'query_operator': nil, 'filter_operator': 'contains' }])

          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        end
      end

      context 'when filtering messages based on conversation attributes' do
        let(:conversation) { create(:conversation, account: account, status: :open, priority: :high) }
        let(:message) do
          create(:message, account: account, conversation: conversation, content: 'Test message',
                           inbox: conversation.inbox, message_type: :incoming)
        end

        it 'will return true when conversation status matches' do
          rule.update!(conditions: [{ 'values': ['open'], 'attribute_key': 'status', 'query_operator': nil, 'filter_operator': 'equal_to' }])
          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        end

        it 'will return false when conversation status does not match' do
          rule.update!(conditions: [{ 'values': ['resolved'], 'attribute_key': 'status', 'query_operator': nil, 'filter_operator': 'equal_to' }])
          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(false)
        end

        it 'will return true when conversation priority matches' do
          rule.update!(conditions: [{ 'values': ['high'], 'attribute_key': 'priority', 'query_operator': nil, 'filter_operator': 'equal_to' }])
          expect(described_class.new(rule, conversation, { message: message, changed_attributes: {} }).perform).to be(true)
        end
      end
    end

    context 'when conditions based on labels' do
      before do
        conversation.add_labels(['bug'])
      end

      context 'when filter_operator is equal_to' do
        before do
          rule.conditions = [
            { 'values': ['bug'], 'attribute_key': 'labels', 'query_operator': nil, 'filter_operator': 'equal_to' }
          ]
          rule.save!
        end

        it 'will return true when conversation has the label' do
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
        end

        it 'will return false when conversation does not have the label' do
          rule.conditions = [
            { 'values': ['feature'], 'attribute_key': 'labels', 'query_operator': nil, 'filter_operator': 'equal_to' }
          ]
          rule.save!
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
        end
      end

      context 'when filter_operator is not_equal_to' do
        before do
          rule.conditions = [
            { 'values': ['feature'], 'attribute_key': 'labels', 'query_operator': nil, 'filter_operator': 'not_equal_to' }
          ]
          rule.save!
        end

        it 'will return true when conversation does not have the label' do
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
        end

        it 'will return false when conversation has the label' do
          conversation.update_labels(%w[bug feature])
          expect(conversation.reload.label_list).to match_array(%w[bug feature])
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
        end

        it 'will return false when conversation has any excluded label' do
          rule.update!(conditions: [
                         { 'values': %w[feature enterprise], 'attribute_key': 'labels', 'query_operator': nil,
                           'filter_operator': 'not_equal_to' }
                       ])
          conversation.update_labels(%w[bug enterprise])

          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
        end
      end

      context 'when filter_operator is is_present' do
        before do
          rule.conditions = [
            { 'values': [], 'attribute_key': 'labels', 'query_operator': nil, 'filter_operator': 'is_present' }
          ]
          rule.save!
        end

        it 'will return true when conversation has any labels' do
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
        end

        it 'will return false when conversation has no labels' do
          conversation.update_labels([])
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
        end
      end

      context 'when filter_operator is is_not_present' do
        before do
          rule.conditions = [
            { 'values': [], 'attribute_key': 'labels', 'query_operator': nil, 'filter_operator': 'is_not_present' }
          ]
          rule.save!
        end

        it 'will return false when conversation has any labels' do
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
        end

        it 'will return true when conversation has no labels' do
          conversation.update_labels([])
          expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
        end
      end
    end

    context 'when conditions based on contact country_code' do
      before do
        conversation.update!(additional_attributes: { country_code: 'US' })
        conversation.contact.update!(additional_attributes: { country_code: 'IN' })
        rule.conditions = [
          { 'values': ['IN'], 'attribute_key': 'country_code', 'query_operator': nil, 'filter_operator': 'equal_to' }
        ]
        rule.save!
      end

      it 'matches against the contact additional_attributes' do
        expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(true)
      end

      it 'returns false when the contact country_code does not match' do
        conversation.contact.update!(additional_attributes: { country_code: 'GB' })
        expect(described_class.new(rule, conversation, { changed_attributes: {} }).perform).to be(false)
      end
    end
  end
end
