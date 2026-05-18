require 'rails_helper'

RSpec.describe ChatwootGlpiIntegration::TicketLink, type: :model do
  let(:account) { create(:account) }

  it 'requires at least conversation or kanban_card' do
    link = build(:glpi_ticket_link, account: account, conversation_id: nil, kanban_card_id: nil)
    expect(link).not_to be_valid
    expect(link.errors[:base]).to include('must link to a conversation or a Kanban card')
  end

  it 'enforces unique glpi_ticket_id per account' do
    create(:glpi_ticket_link, account: account, glpi_ticket_id: 42,
                              kanban_card_id: create(:kanban_card, column: create(:kanban_board, account: account).columns.first).id)
    dup = build(:glpi_ticket_link, account: account, glpi_ticket_id: 42,
                                   kanban_card_id: create(:kanban_card, column: create(:kanban_board, account: account).columns.first).id)
    expect(dup).not_to be_valid
  end
end
