require 'rails_helper'

describe Integrations::MutodayFaqReply::Copy do
  let(:copy) { described_class }
  let(:ai) { described_class::AI_DISCLOSURE }
  let(:auto) { described_class::AUTO_DISCLOSURE }

  describe 'the disclosure constants' do
    it 'carries no Liquid delimiter and no Markdown' do
      [ai, auto].each do |label|
        expect(label).not_to match(described_class::LIQUID_DELIMITERS)
        expect(label).not_to include('**', '#', '`', '_', '[](')
      end
    end

    it 'are two different labels' do
      expect(ai).not_to eq(auto)
    end
  end

  describe '.disclosure_for' do
    it 'returns the AI label for every route the model took part in' do
      %w[model model_low_confidence model_no_match model_invalid_id model_timeout
         model_auth model_quota model_server model_config].each do |route|
        expect(copy.disclosure_for(route)).to eq(ai)
      end
    end

    it 'returns the plain automated label for every route the model did not run on' do
      %w[no_corpus non_text denylist noise_forced].each do |route|
        expect(copy.disclosure_for(route)).to eq(auto)
      end
    end

    it 'defaults to the plain automated label for an unknown or blank route' do
      [nil, '', 'something_else'].each do |route|
        expect(copy.disclosure_for(route)).to eq(auto)
      end
    end
  end

  describe '.matched' do
    it 'leads with the AI label, then the answer, then the handoff' do
      body = copy.matched('เปิดทำการ จันทร์-ศุกร์ 08.30-16.30 น.', route: 'model')

      expect(body).to start_with(ai)
      expect(body).to eq("#{ai}\n\nเปิดทำการ จันทร์-ศุกร์ 08.30-16.30 น.\n\n#{described_class::HANDOFF}")
    end

    it 'strips Liquid delimiters from the answer rather than escaping them' do
      body = copy.matched('สวัสดี {{contact.name}} ดูที่ {% if x %}นี่{% endif %}', route: 'model')

      expect(body).not_to match(described_class::LIQUID_DELIMITERS)
      expect(body).to include('สวัสดี contact.name ดูที่')
      expect(body).to start_with(ai)
    end

    it 'truncates a long answer to MAX_ANSWER and still keeps the label and the handoff' do
      body = copy.matched('ก' * 3000, route: 'model')

      expect(body).to start_with(ai)
      expect(body).to end_with(described_class::HANDOFF)
      answer = body.delete_prefix("#{ai}\n\n").delete_suffix("\n\n#{described_class::HANDOFF}")
      expect(answer.length).to eq(described_class::MAX_ANSWER)
    end

    it 'handles a nil or blank answer without raising' do
      expect { copy.matched(nil, route: 'model') }.not_to raise_error
      expect(copy.matched('', route: 'model')).to start_with(ai)
    end
  end

  describe '.unmatched' do
    it 'leads with the AI label when the model ran and found nothing' do
      body = copy.unmatched(route: 'model_no_match')

      expect(body).to start_with(ai)
      expect(body).to include(described_class::ACKNOWLEDGEMENT, described_class::HANDOFF)
    end

    it 'leads with the plain automated label when no model ran — day one, empty corpus' do
      expect(copy.unmatched(route: 'no_corpus')).to start_with(auto)
      expect(copy.unmatched(route: 'non_text')).to start_with(auto)
    end
  end

  describe '.routed' do
    it 'leads with the plain automated label and promises only the handoff' do
      body = copy.routed(route: 'denylist')

      expect(body).to start_with(auto)
      expect(body).to include(described_class::ROUTED_TO_HUMAN)
      expect(body).not_to include(described_class::HANDOFF)
    end
  end

  # C13 — the compliance property has to hold on the string that actually reaches the
  # customer, not on the constant. `content` goes through MessageContentPresenter →
  # MarkdownRendererService#render_line, which collapses the body into one CommonMark
  # paragraph and lets LineRenderer rewrite nodes inside it.
  describe 'the label survives the LINE renderer and the Liquid pass' do
    let(:account) { create(:account) }
    let(:hook) { create(:integrations_hook, :mutoday_faq_reply, account: account) }
    let(:inbox) { hook.inbox }
    let(:contact) { create(:contact, account: account) }
    let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
    let(:conversation) do
      create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
    end
    let(:awkward_answer) do
      <<~ANSWER.strip
        ส่งข่าวได้สามทาง

        - ทางอีเมล
        - ทาง LINE

        ดูรายละเอียดที่ [เว็บไซต์ MU Today](https://mutoday.mahidol.ac.th) หรือพิมพ์ `help`

        **หมายเหตุ** ต้องแนบภาพประกอบด้วย
      ANSWER
    end

    def persist(body)
      conversation.messages.create!(
        account_id: conversation.account_id, inbox_id: conversation.inbox_id,
        message_type: :template, content_type: :text, sender: nil, private: false, content: body
      )
    end

    it 'still leads with the AI label after Liquid and after rendering, with an awkward answer' do
      message = persist(copy.matched(awkward_answer, route: 'model'))

      expect(message.reload.content).to start_with(ai)
      rendered = MessageContentPresenter.new(message).outgoing_content
      expect(rendered).to start_with(ai)
      expect(rendered).to include('https://mutoday.mahidol.ac.th')
    end

    it 'still leads with the plain automated label on the day-one path' do
      message = persist(copy.unmatched(route: 'no_corpus'))

      expect(message.reload.content).to start_with(auto)
      expect(MessageContentPresenter.new(message).outgoing_content).to start_with(auto)
    end

    it 'still leads with the plain automated label on a deny-list hit' do
      message = persist(copy.routed(route: 'denylist'))

      expect(message.reload.content).to start_with(auto)
      expect(MessageContentPresenter.new(message).outgoing_content).to start_with(auto)
    end

    it 'is not rewritten by the before_create Liquid pass, even when the answer looked like Liquid' do
      message = persist(copy.matched('ติดต่อ {{account.name}} ได้ที่ {% raw %}นี่{% endraw %}', route: 'model'))

      expect(message.reload.content).to start_with(ai)
      # The delimiters are gone, so Liquid had nothing to render: the account name is
      # still the literal text the admin typed, not this account's real name.
      expect(message.content).not_to match(described_class::LIQUID_DELIMITERS)
      expect(message.content).to include('account.name')
      expect(message.content).not_to include(account.name)
    end
  end
end
