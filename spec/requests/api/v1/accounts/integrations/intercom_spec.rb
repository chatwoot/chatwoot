require 'rails_helper'

RSpec.describe 'Intercom Integration API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/:account_id/integrations/intercom' do
    it 'returns null when Intercom is not connected' do
      get api_v1_account_integrations_intercom_url(account_id: account.id),
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to be_nil
    end
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/intercom' do
    let(:service) { instance_double(DataImports::Intercom::ConnectionService, perform: hook) }
    let(:hook) { create(:integrations_hook, :intercom, account: account, access_token: 'intercom-token') }

    it 'connects Intercom through the connection service' do
      allow(DataImports::Intercom::ConnectionService).to receive(:new)
        .with(account: account, access_token: 'intercom-token')
        .and_return(service)

      post api_v1_account_integrations_intercom_url(account_id: account.id),
           params: { access_token: 'intercom-token' },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq(hook.id)
      expect(response.parsed_body['settings']).to include('workspace_name' => 'Intercom workspace')
    end

    it 'does not reconnect Intercom while an import is active' do
      hook = create(:integrations_hook, :intercom, account: account, access_token: 'existing-token')
      create(
        :data_import,
        account: account,
        data_type: 'intercom',
        source_type: 'integration',
        source_provider: 'intercom',
        status: :processing,
        integration_hook: hook,
        import_file: nil
      )

      expect(DataImports::Intercom::Client).not_to receive(:new)

      post api_v1_account_integrations_intercom_url(account_id: account.id),
           params: { access_token: 'new-token' },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq('Intercom cannot be connected while an import is active.')
      expect(hook.reload.access_token).to eq('existing-token')
    end

    it 'does not overwrite the token when an import starts while validating Intercom' do
      hook = create(:integrations_hook, :intercom, account: account, access_token: 'existing-token')
      client = instance_double(DataImports::Intercom::Client)
      allow(DataImports::Intercom::Client).to receive(:new).with(access_token: 'new-token').and_return(client)
      allow(client).to receive(:validate!) do
        create(
          :data_import,
          account: account,
          data_type: 'intercom',
          source_type: 'integration',
          source_provider: 'intercom',
          status: :pending,
          integration_hook: hook,
          import_file: nil
        )
      end

      post api_v1_account_integrations_intercom_url(account_id: account.id),
           params: { access_token: 'new-token' },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq('Intercom cannot be connected while an import is active.')
      expect(hook.reload.access_token).to eq('existing-token')
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/integrations/intercom' do
    it 'disconnects Intercom' do
      hook = create(:integrations_hook, :intercom, account: account)

      delete api_v1_account_integrations_intercom_url(account_id: account.id),
             headers: admin.create_new_auth_token,
             as: :json

      expect(response).to have_http_status(:ok)
      expect(Integrations::Hook.exists?(hook.id)).to be(false)
    end

    it 'does not disconnect Intercom while an import is active' do
      hook = create(:integrations_hook, :intercom, account: account)
      create(
        :data_import,
        account: account,
        data_type: 'intercom',
        source_type: 'integration',
        source_provider: 'intercom',
        status: :processing,
        integration_hook: hook,
        import_file: nil
      )

      delete api_v1_account_integrations_intercom_url(account_id: account.id),
             headers: admin.create_new_auth_token,
             as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq('Intercom cannot be disconnected while an import is active.')
      expect(Integrations::Hook.exists?(hook.id)).to be(true)
    end

    it 'does not disconnect Intercom when an import starts inside the account lock' do
      hook = create(:integrations_hook, :intercom, account: account)
      import_created = false
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(Account).to receive(:with_lock) do |locked_account, &block|
        unless import_created
          import_created = true
          create(
            :data_import,
            account: locked_account,
            data_type: 'intercom',
            source_type: 'integration',
            source_provider: 'intercom',
            status: :pending,
            integration_hook: hook,
            import_file: nil
          )
        end
        block.call
      end
      # rubocop:enable RSpec/AnyInstance

      delete api_v1_account_integrations_intercom_url(account_id: account.id),
             headers: admin.create_new_auth_token,
             as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq('Intercom cannot be disconnected while an import is active.')
      expect(Integrations::Hook.exists?(hook.id)).to be(true)
    end
  end
end
