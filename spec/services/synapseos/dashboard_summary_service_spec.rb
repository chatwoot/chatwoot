require 'rails_helper'

# CUSTOMIZAÇÃO_SYNAPSEOS: cobre o KPI "disparos hoje" (shoots_today) do
# dashboard executivo — contatos distintos que receberam ao menos uma outgoing
# hoje (boundary BRT), independente do filtro de período.
RSpec.describe Synapseos::DashboardSummaryService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  def outgoing_to(contact, at:)
    conv = create(:conversation, account: account, inbox: inbox, contact: contact)
    create(:message, account: account, inbox: inbox, conversation: conv,
                     message_type: :outgoing, created_at: at)
  end

  describe '#call kpis[:shoots_today]' do
    it 'conta contatos DISTINTOS que receberam outgoing hoje' do
      c1 = create(:contact, account: account)
      c2 = create(:contact, account: account)
      now = Time.current
      outgoing_to(c1, at: now)
      outgoing_to(c1, at: now) # mesmo contato -> conta 1
      outgoing_to(c2, at: now)

      summary = described_class.new(account).call

      expect(summary[:kpis][:shoots_today]).to eq(2)
    end

    it 'não conta outgoings de dias anteriores' do
      contact = create(:contact, account: account)
      outgoing_to(contact, at: 2.days.ago)

      summary = described_class.new(account).call

      expect(summary[:kpis][:shoots_today]).to eq(0)
    end

    it 'não reage ao filtro de período (sempre hoje)' do
      contact = create(:contact, account: account)
      outgoing_to(contact, at: Time.current)

      # period_days curtíssimo não muda o "hoje"
      summary = described_class.new(account, period_days: 1).call

      expect(summary[:kpis][:shoots_today]).to eq(1)
    end
  end
end
