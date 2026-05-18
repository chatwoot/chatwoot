require 'rails_helper'

RSpec.describe ChatwootKanban::Card, 'soft delete' do
  let(:account) { create(:account) }
  let(:board)   { create(:kanban_board, account: account) }
  let(:column)  { board.columns.first }

  it '#archive! sets archived_at and is excluded from active scope' do
    card = create(:kanban_card, column: column)
    expect { card.archive! }.to change { described_class.active.count }.by(-1)
    expect(card.reload.archived?).to be true
    expect(described_class.archived).to include(card)
  end

  it '#unarchive! restores card to active' do
    card = create(:kanban_card, column: column).tap(&:archive!)
    expect { card.unarchive! }.to change { described_class.active.count }.by(1)
  end
end
