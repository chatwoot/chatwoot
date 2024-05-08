require 'rails_helper'

describe Integrations::Linear::ProcessorService do
  let(:account) { create(:account) }
  let(:api_key) { 'valid_api_key' }
  let(:linear_client) { instance_double(Linear) }
  let(:service) { described_class.new(account: account) }

  before do
    create(:integrations_hook, :linear, account: account)
    allow(Linear).to receive(:new).and_return(linear_client)
  end

  describe '#teams' do
    context 'when Linear client returns valid data' do
      let(:teams_response) do
        { 'teams' => { 'nodes' => [{ 'id' => 'team1', 'name' => 'Team One' }] } }
      end

      it 'returns parsed team data' do
        allow(linear_client).to receive(:teams).and_return(teams_response)
        result = service.teams
        expect(result).to contain_exactly({ 'id' => 'team1', 'name' => 'Team One' })
      end
    end

    context 'when Linear client returns an error' do
      let(:error_response) { { error: 'Some error message' } }

      it 'returns the error' do
        allow(linear_client).to receive(:teams).and_return(error_response)
        result = service.teams
        expect(result).to eq(error_response)
      end
    end
  end

  describe '#team_entites' do
    let(:team_id) { 'team1' }
    let(:entities_response) do
      {
        'users' => { 'nodes' => [{ 'id' => 'user1', 'name' => 'User One' }] },
        'projects' => { 'nodes' => [{ 'id' => 'project1', 'name' => 'Project One' }] },
        'workflowStates' => { 'nodes' => [] },
        'issueLabels' => { 'nodes' => [{ 'id' => 'bug', 'name' => 'Bug' }] }
      }
    end

    context 'when Linear client returns valid data' do
      it 'returns parsed entity data' do
        allow(linear_client).to receive(:team_entites).with(team_id).and_return(entities_response)
        result = service.team_entites(team_id)
        expect(result).to have_key(:users)
        expect(result).to have_key(:projects)
        expect(result).to have_key(:states)
        expect(result).to have_key(:labels)
      end
    end

    context 'when Linear client returns an error' do
      let(:error_response) { { error: 'Some error message' } }

      it 'returns the error' do
        allow(linear_client).to receive(:team_entites).with(team_id).and_return(error_response)
        result = service.team_entites(team_id)
        expect(result).to eq(error_response)
      end
    end
  end
end
