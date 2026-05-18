require 'rails_helper'

RSpec.describe ChatwootKanban::Comment, type: :model do
  let(:account) { create(:account) }
  let(:user)    { create(:user, account: account) }
  let(:card)    { create(:kanban_card, column: create(:kanban_board, account: account).columns.first) }

  it 'is valid with content + author' do
    expect(build(:kanban_comment, card: card, author: user, content: 'hi')).to be_valid
  end

  it 'extracts @mentions automatically' do
    c = create(:kanban_comment, card: card, author: user,
               content: 'Hey @42 and @43 take a look')
    expect(c.mentioned_user_ids).to contain_exactly(42, 43)
  end

  it 'rejects empty content' do
    expect(build(:kanban_comment, card: card, author: user, content: '')).not_to be_valid
  end
end
