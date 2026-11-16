require 'rails_helper'

RSpec.describe Captain::ToolArguments do
  let(:conversation) { create(:conversation) }
  let(:entries) { { 'email' => { 'source' => 'verified.email' }, 'limit' => { 'source' => 'fixed', 'value' => '20' } } }
  let(:settings) { {} }
  let(:tool) { Captain::McpTool.new(param_sources: entries, settings: settings) }
  let(:arguments) { described_class.new(tool, conversation) }
  let(:verified_email) { 'jane@example.com' }

  before do
    allow(Captain::EmailVerification).to receive(:new)
      .and_return(instance_double(Captain::EmailVerification, verified_email: verified_email))
  end

  describe '#fill' do
    it 'sets every sourced value last, so a value from the model cannot replace it' do
      filled = arguments.fill({ email: 'mallory@example.com', limit: '500', status: 'open' })

      expect(filled).to eq({ email: 'jane@example.com', limit: '20', status: 'open' })
    end

    context 'when the customer has not verified an email' do
      let(:verified_email) { nil }

      it 'raises, so the tool does not run' do
        expect { arguments.fill({}) }.to raise_error(Captain::ParamSources::Unavailable)
      end
    end

    context 'when the setting asks for a verified email and no parameter takes it' do
      let(:entries) { {} }
      let(:settings) { { 'requires_email_verification' => true } }
      let(:verified_email) { nil }

      it 'still requires one' do
        expect { arguments.fill({ status: 'open' }) }.to raise_error(Captain::ParamSources::Unavailable)
      end
    end
  end

  describe '#fill_unproven' do
    it 'sets the fixed value and keeps the value the model passed for the verified email' do
      expect(arguments.fill_unproven({ email: 'jane@example.com', limit: '500' })).to eq({ email: 'jane@example.com', limit: '20' })
    end
  end

  describe '#verified?' do
    it 'compares only the values the customer proves' do
      expect(arguments.verified?({ email: ' Jane@Example.com ' })).to be(true)
      expect(arguments.verified?({ email: 'mallory@example.com' })).to be(false)
    end

    context 'when the customer has not verified an email' do
      let(:verified_email) { nil }

      it 'is false' do
        expect(arguments.verified?({ email: 'jane@example.com' })).to be(false)
      end
    end
  end
end
