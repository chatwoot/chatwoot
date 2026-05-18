require 'rails_helper'

RSpec.describe ChatwootKanban::Card, type: :model do
  let(:account) { create(:account) }
  let(:board)   { create(:kanban_board, account: account) }
  let(:column)  { board.columns.first }

  it 'is valid with title, column, position' do
    expect(build(:kanban_card, column: column)).to be_valid
  end

  it 'requires title' do
    expect(build(:kanban_card, column: column, title: nil)).not_to be_valid
  end

  describe 'scopes' do
    it '.overdue returns only cards past due' do
      past = create(:kanban_card, column: column, due_at: 1.day.ago)
      _future = create(:kanban_card, column: column, due_at: 1.day.from_now)
      _no_due = create(:kanban_card, column: column)
      expect(described_class.overdue).to contain_exactly(past)
    end

    it '.for_account filters by board.account_id' do
      other_board   = create(:kanban_board, account: create(:account))
      other_card    = create(:kanban_card, column: other_board.columns.first)
      mine          = create(:kanban_card, column: column)
      expect(described_class.for_account(account.id)).to include(mine)
      expect(described_class.for_account(account.id)).not_to include(other_card)
    end
  end
end
