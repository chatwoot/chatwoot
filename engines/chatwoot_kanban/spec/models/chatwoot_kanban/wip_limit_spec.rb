require 'rails_helper'

RSpec.describe ChatwootKanban::MoveCardService, 'WIP enforcement' do
  let(:account) { create(:account) }
  let(:board)   { create(:kanban_board, account: account) }
  let(:source)  { board.columns[0] }
  let(:target)  { board.columns[1] }

  before { target.update!(wip_limit: 1) }

  it 'allows move when target column has capacity' do
    target_card = create(:kanban_card, column: target, position: 0)
    target.update!(wip_limit: 2)
    card = create(:kanban_card, column: source, position: 0)
    expect {
      described_class.new(card: card, to_column_id: target.id, position: 1).call
    }.not_to raise_error
    expect(card.reload.column_id).to eq(target.id)
  end

  it 'raises WipLimitExceeded when target is full' do
    create(:kanban_card, column: target, position: 0)
    card = create(:kanban_card, column: source, position: 0)
    expect {
      described_class.new(card: card, to_column_id: target.id, position: 1).call
    }.to raise_error(described_class::WipLimitExceeded)
    expect(card.reload.column_id).to eq(source.id)
  end

  it 'allows reordering within the same column even if at WIP limit' do
    target.update!(wip_limit: 1)
    only_card = create(:kanban_card, column: target, position: 0)
    expect {
      described_class.new(card: only_card, to_column_id: target.id, position: 0).call
    }.not_to raise_error
  end
end
