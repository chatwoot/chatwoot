require 'rails_helper'

describe Integrations::MutodayFaqReply::Eligibility do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :mutoday_faq_reply, account: account) }
  let(:inbox) { hook.inbox }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
  end
  let(:agent) { create(:user, account: account, role: :agent) }

  def inbound(content: 'อยากส่งข่าวต้องทำยังไง', **overrides)
    create(:message, { account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                       sender: contact, content: content, source_id: "line-#{SecureRandom.hex(6)}" }.merge(overrides))
  end

  def gate(message, on_hook: hook)
    described_class.new(message: message, hook: on_hook)
  end

  after do
    Redis::Alfred.delete(format(described_class::MARKER_KEY, conversation_id: conversation.id))
    Redis::Alfred.delete(format(described_class::DEFER_KEY, conversation_id: conversation.id))
  end

  describe 'a clean first LINE text message' do
    it 'is eligible' do
      expect(gate(inbound).rejection).to be_nil
    end

    it 'claims the marker on the way through' do
      gate(inbound).rejection

      expect(Redis::Alfred.get(format(described_class::MARKER_KEY, conversation_id: conversation.id))).to be_present
    end

    it 'is not a forced noise reply' do
      eligibility = gate(inbound)
      eligibility.rejection

      expect(eligibility).not_to be_noise_forced
    end
  end

  describe 'G2 — the loop guard' do
    it 'rejects an outgoing agent reply' do
      message = inbound(message_type: :outgoing, sender: agent)

      expect(gate(message).rejection).to eq({ outcome: 'skipped', guard: 'not_incoming' })
    end

    it 'rejects a template — our own reply can never re-trigger us' do
      message = inbound(message_type: :template, sender: nil)

      expect(gate(message).rejection).to eq({ outcome: 'skipped', guard: 'not_incoming' })
    end

    it 'rejects an activity message' do
      message = inbound(message_type: :activity, sender: nil, content: 'Conversation was marked resolved')

      expect(gate(message).rejection).to eq({ outcome: 'skipped', guard: 'not_incoming' })
    end
  end

  describe 'G3 — the message came off the LINE webhook' do
    it 'rejects a blank source_id' do
      expect(gate(inbound(source_id: nil)).rejection).to eq({ outcome: 'skipped', guard: 'no_source_id' })
    end
  end

  describe 'G4 — a customer is speaking' do
    it 'rejects a User sender' do
      expect(gate(inbound(sender: agent)).rejection).to eq({ outcome: 'skipped', guard: 'sender_not_contact' })
    end

    it 'rejects a message with no sender at all' do
      # Built directly: the factory backfills a sender, so `sender: nil` cannot be expressed
      # through it. The guard tests is_a?(Contact) rather than !is_a?(User) for this reason.
      message = conversation.messages.create!(
        account_id: account.id, inbox_id: inbox.id, message_type: :incoming, content_type: :text,
        sender: nil, content: 'ถามหน่อยครับ', source_id: 'line-no-sender'
      )

      expect(gate(message).rejection).to eq({ outcome: 'skipped', guard: 'sender_not_contact' })
    end
  end

  describe 'G5 — the inbox is LINE' do
    let(:widget_inbox) { create(:inbox, account: account) }
    let(:widget_contact_inbox) { create(:contact_inbox, contact: contact, inbox: widget_inbox) }
    let(:widget_conversation) do
      create(:conversation, account: account, inbox: widget_inbox, contact: contact, contact_inbox: widget_contact_inbox)
    end

    it 'reports a non-LINE inbox as a misconfiguration rather than skipping quietly' do
      message = create(:message, account: account, inbox: widget_inbox, conversation: widget_conversation,
                                 message_type: :incoming, sender: contact, content: 'hello', source_id: 'x')

      expect(gate(message).rejection).to eq({ outcome: 'misconfigured', guard: 'not_line_inbox' })
    end
  end

  describe 'G6 — the kill switch' do
    it 'rejects when mode is off' do
      hook.update!(settings: hook.settings.merge('mode' => 'off'))

      expect(gate(inbound).rejection).to eq({ outcome: 'skipped', guard: 'mode_off' })
    end

    it 'allows shadow and live' do
      %w[shadow live].each do |mode|
        hook.update!(settings: hook.settings.merge('mode' => mode))
        Redis::Alfred.delete(format(described_class::MARKER_KEY, conversation_id: conversation.id))

        expect(gate(inbound).rejection).to be_nil
      end
    end
  end

  describe 'G8 — never talk over a human' do
    it 'rejects when an agent has already replied' do
      message = inbound
      create(:message, account: account, inbox: inbox, conversation: conversation,
                       message_type: :outgoing, sender: agent, content: 'สวัสดีครับ')

      expect(gate(message).rejection).to eq({ outcome: 'skipped', guard: 'already_answered' })
    end

    it 'rejects when an agent has left a private note' do
      message = inbound
      create(:message, account: account, inbox: inbox, conversation: conversation,
                       message_type: :outgoing, sender: agent, content: 'internal', private: true)

      expect(gate(message).rejection).to eq({ outcome: 'skipped', guard: 'already_answered' })
    end

    it 'rejects a retry that follows our own successful send, as already_answered' do
      message = inbound
      create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :template,
                       sender: nil, content: '[ข้อความอัตโนมัติ] ...',
                       additional_attributes: { 'mutoday_faq_reply' => { 'version' => 1 } })

      expect(gate(message).rejection).to eq({ outcome: 'skipped', guard: 'already_answered' })
    end

    it 'reports a greeting or out-of-office template as foreign_template, never a quiet skip' do
      message = inbound
      create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :template,
                       sender: nil, content: 'ขอบคุณที่ติดต่อเข้ามา นอกเวลาทำการ')

      expect(gate(message).rejection).to eq({ outcome: 'misconfigured', guard: 'foreign_template' })
    end

    it 'exposes the same test on its own, so the caller can re-run it before writing' do
      message = inbound
      eligibility = gate(message)
      expect(eligibility.already_answered).to be_nil

      create(:message, account: account, inbox: inbox, conversation: conversation,
                       message_type: :outgoing, sender: agent, content: 'ตอบแล้วครับ')

      expect(eligibility.already_answered).to eq('already_answered')
    end
  end

  describe "G7' — the greeting deferral" do
    let(:defer_key) { format(described_class::DEFER_KEY, conversation_id: conversation.id) }
    let(:marker_key) { format(described_class::MARKER_KEY, conversation_id: conversation.id) }

    ['สวัสดีครับ', 'สวัสดี', 'หวัดดี', 'ดีครับ', 'ค่ะ', 'โอเค', 'hi', 'Hello', 'ขอสอบถาม', 'ok', '👍'].each do |greeting|
      it "defers #{greeting}" do
        expect(gate(inbound(content: greeting)).rejection).to eq({ outcome: 'skipped', guard: 'noise_deferred' })
      end
    end

    it 'does not claim the marker, so the next message is treated as the first' do
      gate(inbound(content: 'สวัสดีครับ')).rejection

      expect(Redis::Alfred.get(marker_key)).to be_nil
      expect(gate(inbound(content: 'อยากส่งข่าวต้องทำยังไง')).rejection).to be_nil
    end

    it 'stops deferring after two, and marks the reply as forced' do
      2.times { expect(gate(inbound(content: 'สวัสดีครับ')).rejection).to eq({ outcome: 'skipped', guard: 'noise_deferred' }) }

      third = gate(inbound(content: 'สวัสดีครับ'))
      expect(third.rejection).to be_nil
      expect(third).to be_noise_forced
    end

    it 'counts deferrals per conversation with a TTL' do
      gate(inbound(content: 'สวัสดีครับ')).rejection

      expect(Redis::Alfred.get(defer_key)).to eq('1')
      expect(Redis::Alfred.ttl(defer_key)).to be_positive
    end

    it 'does not defer a greeting that carries a real question' do
      expect(gate(inbound(content: 'สวัสดีครับ อยากสอบถามเรื่องรับสมัคร')).rejection).to be_nil
    end

    it 'does not defer a photo — waiting cannot improve it' do
      message = inbound(content: nil, content_type: :text)

      expect(gate(message).rejection).to be_nil
    end

    it 'does not defer a sticker' do
      message = inbound(content: '![sticker](https://stickershop.line-scdn.net/1.png)', content_type: :sticker)

      expect(gate(message).rejection).to be_nil
    end
  end

  describe 'G9 — the atomic once-per-conversation claim' do
    it 'lets a retry of the same message through' do
      message = inbound
      expect(gate(message).rejection).to be_nil

      expect(gate(message).rejection).to be_nil
    end

    it 'blocks a different message on the same conversation' do
      expect(gate(inbound).rejection).to be_nil

      expect(gate(inbound(content: 'ถามอีกเรื่องครับ')).rejection).to eq({ outcome: 'skipped', guard: 'marker_claimed' })
    end

    it 'sets the marker to the winning message id, with a TTL' do
      message = inbound
      gate(message).rejection

      key = format(described_class::MARKER_KEY, conversation_id: conversation.id)
      expect(Redis::Alfred.get(key)).to eq(message.id.to_s)
      expect(Redis::Alfred.ttl(key)).to be_positive
    end
  end

  describe 'C14 — Redis is unreachable' do
    it 'fails closed with stage=redis rather than replying blind' do
      allow(Redis::Alfred).to receive(:set).and_raise(Redis::CannotConnectError, 'no connection')

      rejection = gate(inbound).rejection

      expect(rejection[:outcome]).to eq('failed')
      expect(rejection[:stage]).to eq('redis')
      expect(rejection[:error]).to eq('Redis::CannotConnectError')
    end

    it 'fails closed when the deferral counter is the thing that cannot be reached' do
      allow(Redis::Alfred).to receive(:incr).and_raise(Redis::TimeoutError, 'timeout')

      rejection = gate(inbound(content: 'สวัสดีครับ')).rejection

      expect(rejection[:outcome]).to eq('failed')
      expect(rejection[:stage]).to eq('redis')
    end
  end

  describe 'guard ordering' do
    it 'reports the structural reason first, not the configuration one' do
      widget_inbox = create(:inbox, account: account)
      widget_contact_inbox = create(:contact_inbox, contact: contact, inbox: widget_inbox)
      widget_conversation = create(:conversation, account: account, inbox: widget_inbox,
                                                  contact: contact, contact_inbox: widget_contact_inbox)
      message = create(:message, account: account, inbox: widget_inbox, conversation: widget_conversation,
                                 message_type: :outgoing, sender: agent, content: 'hello')

      expect(gate(message).rejection).to eq({ outcome: 'skipped', guard: 'not_incoming' })
    end

    it 'does not touch Redis at all when a structural guard already rejected' do
      allow(Redis::Alfred).to receive(:set)

      gate(inbound(message_type: :template, sender: nil)).rejection

      expect(Redis::Alfred).not_to have_received(:set)
    end
  end
end
