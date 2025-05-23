require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::SearchLinearIssuesService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:user) { create(:user, account: account) }
  let(:service) { described_class.new(assistant, user: user) }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('search_linear_issues')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to eq('Search Linear issues based on a search term')
    end
  end

  describe '#parameters' do
    it 'returns the expected parameter schema' do
      expect(service.parameters).to eq(
        {
          type: 'object',
          properties: {
            term: {
              type: 'string',
              description: 'The search term to find Linear issues'
            }
          },
          required: %w[term]
        }
      )
    end
  end

  describe '#active?' do
    context 'when Linear integration is enabled' do
      before do
        create(:integrations_hook, :linear, account: account)
      end

      context 'when user is present' do
        it 'returns true' do
          expect(service.active?).to be true
        end
      end

      context 'when user is not present' do
        let(:service) { described_class.new(assistant) }

        it 'returns false' do
          expect(service.active?).to be false
        end
      end
    end

    context 'when Linear integration is not enabled' do
      context 'when user is present' do
        it 'returns false' do
          expect(service.active?).to be false
        end
      end

      context 'when user is not present' do
        let(:service) { described_class.new(assistant) }

        it 'returns false' do
          expect(service.active?).to be false
        end
      end
    end
  end

  describe '#execute' do
    context 'when Linear integration is not enabled' do
      it 'returns error message' do
        expect(service.execute({ 'term' => 'test' })).to eq('Linear integration is not enabled')
      end
    end

    context 'when Linear integration is enabled' do
      let(:linear_service) { instance_double(Integrations::Linear::ProcessorService) }

      before do
        create(:integrations_hook, :linear, account: account)
        allow(Integrations::Linear::ProcessorService).to receive(:new).and_return(linear_service)
      end

      context 'when term is blank' do
        it 'returns error message' do
          expect(service.execute({ 'term' => '' })).to eq('Missing required parameters')
        end
      end

      context 'when search returns error' do
        before do
          allow(linear_service).to receive(:search_issue).and_return({ error: 'API Error' })
        end

        it 'returns the error message' do
          expect(service.execute({ 'term' => 'test' })).to eq('API Error')
        end
      end

      context 'when search returns no issues' do
        before do
          allow(linear_service).to receive(:search_issue).and_return({ data: [] })
        end

        it 'returns no issues found message' do
          expect(service.execute({ 'term' => 'test' })).to eq('No issues found, I should try another similar search term')
        end
      end

      context 'when search returns issues' do
        let(:issues) do
          [{
            'title' => 'Test Issue',
            'id' => 'TEST-123',
            'state' => { 'name' => 'In Progress' },
            'priority' => 4,
            'assignee' => { 'name' => 'John Doe' },
            'description' => 'Test description'
          }]
        end

        before do
          allow(linear_service).to receive(:search_issue).and_return({ data: issues })
        end

        it 'returns formatted issues' do
          result = service.execute({ 'term' => 'test' })
          expect(result).to include('Total number of issues: 1')
          expect(result).to include('Title: Test Issue')
          expect(result).to include('ID: TEST-123')
          expect(result).to include('State: In Progress')
          expect(result).to include('Priority: Low')
          expect(result).to include('Assignee: John Doe')
          expect(result).to include('Description: Test description')
        end
      end
    end
  end
end
