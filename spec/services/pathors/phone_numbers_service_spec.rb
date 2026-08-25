require 'rails_helper'

describe Pathors::PhoneNumbersService do
  let(:account) { create(:account) }
  let!(:hook) { create(:integrations_hook, :pathors, account: account, access_token: 'pathors_access_token') }
  let(:inbox) { create(:channel_voice, account: account, phone_number: '+886277001234').inbox }
  let(:base_url) { 'https://api.pathors.com/org/org_ac9/integration/chatwoot' }
  let(:numbers_url) { "#{base_url}/phone_numbers" }
  let(:binding_url) { "#{base_url}/phone_numbers/pn_x9k2/binding" }
  let(:number_payload) do
    {
      id: 'pn_x9k2',
      phone_number: '+886277001234',
      extension: nil,
      label: '台北客服代表號',
      status: 'active',
      binding: nil
    }
  end

  describe '#list' do
    it 'returns the payload of numbers' do
      stub_request(:get, numbers_url)
        .with(headers: { 'Authorization' => 'Bearer pathors_access_token' })
        .to_return(status: 200, body: { payload: [number_payload] }.to_json, headers: { 'Content-Type' => 'application/json' })

      numbers = described_class.new(account: account).list

      expect(numbers.map { |number| number['id'] }).to eq(['pn_x9k2'])
      expect(numbers.first['phone_number']).to eq('+886277001234')
    end

    it 'forces a token refresh and retries once on a 401' do
      stub_request(:get, numbers_url)
        .with(headers: { 'Authorization' => 'Bearer pathors_access_token' })
        .to_return(status: 401, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, 'https://api.pathors.com/oauth/token')
        .to_return(
          status: 200,
          body: { access_token: 'refreshed_access_token', refresh_token: 'next_refresh_token', expires_in: 7200 }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      stub_request(:get, numbers_url)
        .with(headers: { 'Authorization' => 'Bearer refreshed_access_token' })
        .to_return(status: 200, body: { payload: [number_payload] }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(described_class.new(account: account).list.first['id']).to eq('pn_x9k2')
      expect(hook.reload.settings['organization_id']).to eq('org_ac9')
    end

    it 'raises when the registry keeps failing' do
      stub_request(:get, numbers_url).to_return(status: 500, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      expect { described_class.new(account: account).list }
        .to(raise_error { |error| expect(error.class.name).to eq('CustomExceptions::Pathors::RequestFailed') })
    end
  end

  describe '#bind' do
    it 'sends the account, inbox, number and answering project and returns the binding' do
      stub_request(:put, binding_url)
        .with(
          headers: { 'Authorization' => 'Bearer pathors_access_token' },
          body: { account_id: account.id, inbox_id: inbox.id, phone_number: '+886277001234', project_id: 'proj_123' }.to_json
        )
        .to_return(
          status: 200,
          body: { binding: { account_id: account.id, inbox_id: inbox.id } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = described_class.new(account: account).bind(phone_number_id: 'pn_x9k2', inbox: inbox, project_id: 'proj_123')

      expect(result['inbox_id']).to eq(inbox.id)
    end

    it 're-routes the number when the same inbox is bound to another project' do
      rebind_request = stub_request(:put, binding_url)
                       .with(body: { account_id: account.id, inbox_id: inbox.id, phone_number: '+886277001234', project_id: 'proj_456' }.to_json)
                       .to_return(
                         status: 200,
                         body: { binding: { account_id: account.id, inbox_id: inbox.id, project_id: 'proj_456' } }.to_json,
                         headers: { 'Content-Type' => 'application/json' }
                       )

      result = described_class.new(account: account).bind(phone_number_id: 'pn_x9k2', inbox: inbox, project_id: 'proj_456')

      expect(result['project_id']).to eq('proj_456')
      expect(rebind_request).to have_been_requested
    end

    it 'raises a distinct error when the number is already bound' do
      stub_request(:put, binding_url).to_return(
        status: 409,
        body: { error: 'already_bound', binding: { account_id: 7, inbox_id: 42 } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      expect { described_class.new(account: account).bind(phone_number_id: 'pn_x9k2', inbox: inbox, project_id: 'proj_123') }
        .to(raise_error { |error| expect(error.class.name).to eq('CustomExceptions::Pathors::PhoneNumberAlreadyBound') })
    end

    it 'raises a binding rejection on a number mismatch' do
      stub_request(:put, binding_url).to_return(
        status: 422, body: { error: 'number_mismatch' }.to_json, headers: { 'Content-Type' => 'application/json' }
      )

      expect { described_class.new(account: account).bind(phone_number_id: 'pn_x9k2', inbox: inbox, project_id: 'proj_123') }
        .to(raise_error { |error| expect(error.class.name).to eq('CustomExceptions::Pathors::BindingRejected') })
    end

    it 'raises a binding rejection on a project mismatch' do
      stub_request(:put, binding_url).to_return(
        status: 422, body: { error: 'project_mismatch' }.to_json, headers: { 'Content-Type' => 'application/json' }
      )

      expect { described_class.new(account: account).bind(phone_number_id: 'pn_x9k2', inbox: inbox, project_id: 'proj_123') }
        .to(raise_error { |error| expect(error.class.name).to eq('CustomExceptions::Pathors::BindingRejected') })
    end
  end

  describe '#unbind' do
    it 'returns true when Pathors releases the binding' do
      stub_request(:delete, binding_url).to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(described_class.new(account: account).unbind(phone_number_id: 'pn_x9k2')).to be(true)
    end

    it 'returns false without raising when Pathors errors' do
      stub_request(:delete, binding_url).to_return(status: 500, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(described_class.new(account: account).unbind(phone_number_id: 'pn_x9k2')).to be(false)
    end

    it 'returns false without raising when the integration is gone' do
      hook.destroy!

      expect(described_class.new(account: account).unbind(phone_number_id: 'pn_x9k2')).to be(false)
    end
  end

  describe 'when the integration is not connected' do
    it 'raises when the hook is missing' do
      hook.destroy!

      expect { described_class.new(account: account).list }
        .to(raise_error { |error| expect(error.class.name).to eq('CustomExceptions::Pathors::IntegrationNotConnected') })
    end

    it 'raises when the hook is disabled' do
      hook.update!(status: :disabled)

      expect { described_class.new(account: account).list }
        .to(raise_error { |error| expect(error.class.name).to eq('CustomExceptions::Pathors::IntegrationNotConnected') })
    end

    it 'raises when the hook carries no organization id' do
      hook.update!(settings: { project_id: 'proj_123', refresh_token: 'pathors_refresh_token' })

      expect { described_class.new(account: account).list }
        .to(raise_error { |error| expect(error.class.name).to eq('CustomExceptions::Pathors::IntegrationNotConnected') })
    end
  end
end
