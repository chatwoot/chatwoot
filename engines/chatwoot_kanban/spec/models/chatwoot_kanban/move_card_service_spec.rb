require 'rails_helper'

RSpec.describe ChatwootKanban::MoveCardService do
  let(:account) { create(:account) }
  let(:user)    { create(:user, account: account) }
  let(:board)   { create(:kanban_board, account: account) }
  let(:col_a)   { board.columns[0] }
  let(:col_b)   { board.columns[1] }

  before do
    @c1 = create(:kanban_card, column: col_a, position: 0, title: 'A1')
    @c2 = create(:kanban_card, column: col_a, position: 1, title: 'A2')
    @c3 = create(:kanban_card, column: col_b, position: 0, title: 'B1')
  end

  it 'moves a card across columns into the requested position' do
    described_class.new(card: @c1, to_column_id: col_b.id, position: 0, actor: user).call
    expect(@c1.reload.column_id).to eq(col_b.id)
    expect(col_b.cards.order(:position).pluck(:title)).to eq(%w[A1 B1])
  end

  it 'rebalances source column positions after move' do
    described_class.new(card: @c1, to_column_id: col_b.id, position: 0, actor: user).call
    expect(col_a.reload.cards.order(:position).pluck(:title)).to eq(%w[A2])
    expect(col_a.cards.find_by(title: 'A2').position).to eq(0)
  end

  it 'records a moved activity' do
    expect {
      described_class.new(card: @c1, to_column_id: col_b.id, position: 0, actor: user).call
    }.to change { @c1.activities.where(action: 'moved').count }.by(1)
  end

  it 'refuses to move to a column in another board' do
    other_board = create(:kanban_board, account: account)
    expect {
      described_class.new(card: @c1, to_column_id: other_board.columns.first.id, position: 0).call
    }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
