require 'rails_helper'

RSpec.describe 'ChatwootKanban::Api::V1::Boards', type: :request do
  let(:account) { create(:account) }
  let(:admin)   { create(:user, account: account, role: :administrator) }
  let(:agent)   { create(:user, account: account, role: :agent) }
  let(:headers) { admin.create_new_auth_token }

  describe 'GET /api/v1/accounts/:account_id/kanban/boards' do
    it 'lists active boards for the account' do
      mine = create(:kanban_board, account: account)
      archived = create(:kanban_board, account: account)
      archived.archive!
      other = create(:kanban_board, account: create(:account))

      get "/api/v1/accounts/#{account.id}/kanban/boards", headers: headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body['data'].map { |b| b['id'] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(archived.id, other.id)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/kanban/boards' do
    it 'creates a board for administrators' do
      expect {
        post "/api/v1/accounts/#{account.id}/kanban/boards",
             params: { board: { name: 'Sales pipeline' } }, headers: headers
      }.to change(ChatwootKanban::Board, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'forbids agents from creating' do
      agent_headers = agent.create_new_auth_token
      post "/api/v1/accounts/#{account.id}/kanban/boards",
           params: { board: { name: 'x' } }, headers: agent_headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/kanban/boards/:id/duplicate' do
    it 'duplicates the board with columns and cards' do
      source = create(:kanban_board, account: account, name: 'Source')
      create(:kanban_card, column: source.columns.first, title: 'C1')

      expect {
        post "/api/v1/accounts/#{account.id}/kanban/boards/#{source.id}/duplicate", headers: headers
      }.to change(ChatwootKanban::Board, :count).by(1)
      copy = ChatwootKanban::Board.order(:id).last
      expect(copy.name).to eq('Source (copy)')
      expect(copy.cards.pluck(:title)).to include('C1')
    end
  end
end
