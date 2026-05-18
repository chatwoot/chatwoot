require 'rails_helper'

RSpec.describe ChatwootKanban::Board, type: :model do
  let(:account) { create(:account) }

  it 'is valid with name and account' do
    expect(build(:kanban_board, account: account)).to be_valid
  end

  it 'requires a name' do
    board = build(:kanban_board, account: account, name: nil)
    expect(board).not_to be_valid
  end

  it 'seeds default columns after creation' do
    board = create(:kanban_board, account: account)
    expect(board.columns.pluck(:name)).to eq(%w[Backlog Doing Done])
  end

  describe '#archive! / #unarchive!' do
    let(:board) { create(:kanban_board, account: account) }

    it 'sets and clears archived_at' do
      expect { board.archive! }.to change { board.reload.archived? }.from(false).to(true)
      expect { board.unarchive! }.to change { board.reload.archived? }.from(true).to(false)
    end

    it 'scopes active / archived correctly' do
      board.archive!
      expect(described_class.active).not_to include(board)
      expect(described_class.archived).to include(board)
    end
  end
end
