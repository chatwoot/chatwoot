require 'rails_helper'

RSpec.describe 'ChatwootKanban::Api::V1::Cards', type: :request do
  let(:account) { create(:account) }
  let(:user)    { create(:user, account: account, role: :agent) }
  let(:headers) { user.create_new_auth_token }
  let(:board)   { create(:kanban_board, account: account) }
  let(:col_a)   { board.columns[0] }
  let(:col_b)   { board.columns[1] }

  describe 'PATCH /api/v1/accounts/:aid/kanban/boards/:bid/cards/move' do
    it 'moves a card to a new column at position 0' do
      card = create(:kanban_card, column: col_a, position: 0)
      patch "/api/v1/accounts/#{account.id}/kanban/boards/#{board.id}/cards/move",
            params: { card_id: card.id, to_column_id: col_b.id, position: 0 },
            headers: headers
      expect(response).to have_http_status(:ok)
      expect(card.reload.column_id).to eq(col_b.id)
    end
  end

  describe 'POST /api/v1/accounts/:aid/kanban/boards/:bid/cards' do
    it 'creates a card and an activity' do
      expect {
        post "/api/v1/accounts/#{account.id}/kanban/boards/#{board.id}/cards",
             params: { card: { column_id: col_a.id, title: 'New' } },
             headers: headers
      }.to change(ChatwootKanban::Card, :count).by(1)
         .and change(ChatwootKanban::CardActivity, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end
end
