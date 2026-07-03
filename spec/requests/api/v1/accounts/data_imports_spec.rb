require 'rails_helper'

RSpec.describe 'Data Imports API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'POST /api/v1/accounts/:account_id/data_imports' do
    let!(:hook) { create(:integrations_hook, :intercom, account: account) }

    it 'creates and enqueues an Intercom import' do
      expect do
        post api_v1_account_data_imports_url(account_id: account.id),
             params: { name: 'Migration run', import_types: %w[contacts conversations] },
             headers: admin.create_new_auth_token,
             as: :json
      end.to have_enqueued_job(DataImports::Intercom::ImportJob)

      expect(response).to have_http_status(:ok)
      data_import = account.data_imports.last
      expect(data_import).to have_attributes(
        name: 'Migration run',
        data_type: 'intercom',
        source_type: 'integration',
        source_provider: 'intercom',
        integration_hook_id: hook.id,
        initiated_by_id: admin.id
      )
      expect(data_import.import_types).to eq(%w[contacts conversations])
      expect(response.parsed_body['source_provider']).to eq('intercom')
    end

    it 'returns the active Intercom import instead of creating a duplicate' do
      active_import = create(
        :data_import,
        account: account,
        data_type: 'intercom',
        source_type: 'integration',
        source_provider: 'intercom',
        import_types: %w[contacts conversations],
        integration_hook: hook,
        status: :processing,
        import_file: nil
      )

      expect do
        post api_v1_account_data_imports_url(account_id: account.id),
             params: { name: 'Second run', import_types: %w[contacts conversations] },
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to have_enqueued_job(DataImports::Intercom::ImportJob)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq(active_import.id)
      expect(account.data_imports.where(data_type: 'intercom', source_provider: 'intercom').count).to eq(1)
    end

    it 'rejects unsupported import types instead of silently importing everything' do
      expect do
        post api_v1_account_data_imports_url(account_id: account.id),
             params: { name: 'Migration run', import_types: %w[companies] },
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to have_enqueued_job(DataImports::Intercom::ImportJob)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to include('Import types contains unsupported values: companies')
    end
  end

  describe 'POST /api/v1/accounts/:account_id/data_imports/:id/start' do
    let(:hook) { create(:integrations_hook, :intercom, account: account) }
    let(:data_import) do
      create(
        :data_import,
        account: account,
        data_type: 'intercom',
        source_type: 'integration',
        source_provider: 'intercom',
        import_types: %w[contacts conversations],
        integration_hook: hook,
        import_file: nil
      )
    end

    it 'restarts abandoned imports' do
      data_import.update!(status: :abandoned, abandoned_at: 1.hour.ago)

      expect do
        post start_api_v1_account_data_import_url(account_id: account.id, id: data_import.id),
             headers: admin.create_new_auth_token,
             as: :json
      end.to have_enqueued_job(DataImports::Intercom::ImportJob).with(data_import)

      expect(response).to have_http_status(:ok)
      expect(data_import.reload).to be_pending
      expect(data_import.abandoned_at).to be_nil
    end

    it 'does not enqueue duplicate jobs for active imports' do
      data_import.update!(status: :processing)

      expect do
        post start_api_v1_account_data_import_url(account_id: account.id, id: data_import.id),
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to have_enqueued_job(DataImports::Intercom::ImportJob)

      expect(response).to have_http_status(:ok)
      expect(data_import.reload).to be_processing
    end

    it 'returns the active Intercom import instead of restarting another import' do
      data_import.update!(status: :abandoned, abandoned_at: 1.hour.ago)
      active_import = create(
        :data_import,
        account: account,
        data_type: 'intercom',
        source_type: 'integration',
        source_provider: 'intercom',
        import_types: %w[contacts conversations],
        integration_hook: hook,
        status: :processing,
        import_file: nil
      )

      expect do
        post start_api_v1_account_data_import_url(account_id: account.id, id: data_import.id),
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to have_enqueued_job(DataImports::Intercom::ImportJob)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq(active_import.id)
      expect(data_import.reload).to be_abandoned
    end

    it 'does not restart imports when Intercom is disconnected' do
      data_import.update!(status: :abandoned, abandoned_at: 1.hour.ago)
      hook.destroy!

      expect do
        post start_api_v1_account_data_import_url(account_id: account.id, id: data_import.id),
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to have_enqueued_job(DataImports::Intercom::ImportJob)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq('Intercom is not connected.')
      expect(data_import.reload).to be_abandoned
    end
  end

  describe 'POST /api/v1/accounts/:account_id/data_imports/:id/abandon' do
    let(:hook) { create(:integrations_hook, :intercom, account: account) }
    let(:data_import) do
      create(
        :data_import,
        account: account,
        data_type: 'intercom',
        source_type: 'integration',
        source_provider: 'intercom',
        import_types: %w[contacts conversations],
        integration_hook: hook,
        import_file: nil
      )
    end

    it 'abandons active imports' do
      data_import.update!(status: :processing)

      post abandon_api_v1_account_data_import_url(account_id: account.id, id: data_import.id),
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(data_import.reload).to be_abandoned
      expect(data_import.abandoned_at).to be_present
    end

    it 'does not rewrite completed imports as abandoned' do
      data_import.update!(status: :completed, completed_at: 1.hour.ago)

      post abandon_api_v1_account_data_import_url(account_id: account.id, id: data_import.id),
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(data_import.reload).to be_completed
      expect(data_import.abandoned_at).to be_nil
    end
  end

  describe 'GET /api/v1/accounts/:account_id/data_imports/:id' do
    let(:hook) { create(:integrations_hook, :intercom, account: account) }
    let(:data_import) do
      create(
        :data_import,
        account: account,
        name: 'July Intercom migration',
        data_type: 'intercom',
        source_type: 'integration',
        source_provider: 'intercom',
        import_types: %w[contacts conversations],
        integration_hook: hook,
        initiated_by: admin,
        import_file: nil
      )
    end

    it 'returns import details with recent errors' do
      data_import.import_errors.create!(
        error_code: 'Intercom::RateLimited',
        message: 'Rate limited',
        source_object_type: 'conversation',
        source_object_id: 'conversation_1'
      )
      data_import.import_errors.create!(
        error_code: 'DataImports::Intercom::SkippedMessage',
        message: 'Skipped blank message',
        source_object_type: 'message',
        source_object_id: 'conversation:conversation_1:part:blank_part',
        details: { kind: 'skipped', reason: 'blank_or_unsupported_intercom_part' }
      )

      get api_v1_account_data_import_url(account_id: account.id, id: data_import.id),
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'id' => data_import.id,
        'name' => 'July Intercom migration',
        'source_provider' => 'intercom',
        'import_errors_count' => 1,
        'skip_logs_count' => 1
      )
      expect(response.parsed_body['import_errors'].first).to include(
        'error_code' => 'Intercom::RateLimited',
        'message' => 'Rate limited',
        'source_object_type' => 'conversation',
        'source_object_id' => 'conversation_1'
      )
      expect(response.parsed_body['skip_logs'].first).to include(
        'kind' => 'skipped',
        'error_code' => 'DataImports::Intercom::SkippedMessage',
        'source_object_type' => 'message',
        'source_object_id' => 'conversation:conversation_1:part:blank_part'
      )
    end

    it 'paginates skip logs in pages of 15' do
      16.times do |index|
        data_import.import_errors.create!(
          error_code: 'DataImports::Intercom::AlreadyImported',
          message: 'Already imported in a previous import.',
          source_object_type: 'message',
          source_object_id: "message_#{index}",
          details: { kind: 'skipped', reason: 'already_imported' },
          created_at: Time.zone.at(index)
        )
      end

      get api_v1_account_data_import_url(account_id: account.id, id: data_import.id, skip_logs_page: 2),
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['skip_logs'].size).to eq(1)
      expect(response.parsed_body['skip_logs'].first).to include('source_object_id' => 'message_0')
      expect(response.parsed_body['skip_logs_pagination']).to include(
        'current_page' => 2,
        'per_page' => 15,
        'total_count' => 16,
        'total_pages' => 2
      )
    end

    it 'filters skip logs by source object type with counts for each type' do
      3.times do |index|
        data_import.import_errors.create!(
          error_code: 'DataImports::Intercom::AlreadyImported',
          message: 'Already imported in a previous import.',
          source_object_type: 'contact',
          source_object_id: "contact_#{index}",
          details: { kind: 'skipped', reason: 'already_imported' }
        )
      end
      2.times do |index|
        data_import.import_errors.create!(
          error_code: 'DataImports::Intercom::AlreadyImported',
          message: 'Already imported in a previous import.',
          source_object_type: 'message',
          source_object_id: "message_#{index}",
          details: { kind: 'skipped', reason: 'already_imported' }
        )
      end

      get api_v1_account_data_import_url(account_id: account.id, id: data_import.id, skip_logs_type: 'contact'),
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['skip_logs'].pluck('source_object_type').uniq).to eq(['contact'])
      expect(response.parsed_body['skip_logs_pagination']).to include(
        'current_page' => 1,
        'per_page' => 15,
        'total_count' => 3,
        'total_pages' => 1
      )
      expect(response.parsed_body['skip_logs_filters']).to include(
        'selected_source_object_type' => 'contact',
        'counts_by_type' => include('contact' => 3, 'message' => 2)
      )
    end

    it 'paginates error logs in pages of 15' do
      16.times do |index|
        data_import.import_errors.create!(
          error_code: 'Intercom::RateLimited',
          message: 'Rate limited',
          source_object_type: 'conversation',
          source_object_id: "conversation_#{index}",
          created_at: Time.zone.at(index)
        )
      end

      get api_v1_account_data_import_url(account_id: account.id, id: data_import.id, import_errors_page: 2),
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['import_errors'].size).to eq(1)
      expect(response.parsed_body['import_errors'].first).to include('source_object_id' => 'conversation_0')
      expect(response.parsed_body['import_errors_pagination']).to include(
        'current_page' => 2,
        'per_page' => 15,
        'total_count' => 16,
        'total_pages' => 2
      )
    end
  end

  describe 'GET /api/v1/accounts/:account_id/data_imports/:id/skip_logs.csv' do
    let(:hook) { create(:integrations_hook, :intercom, account: account) }
    let(:data_import) do
      create(
        :data_import,
        account: account,
        data_type: 'intercom',
        source_type: 'integration',
        source_provider: 'intercom',
        import_types: %w[contacts conversations],
        integration_hook: hook,
        initiated_by: admin,
        import_file: nil
      )
    end

    it 'downloads skip logs as CSV' do
      data_import.import_errors.create!(
        error_code: 'DataImports::Intercom::SkippedMessage',
        message: 'Skipped blank message',
        source_object_type: 'message',
        source_object_id: 'conversation:conversation_1:part:blank_part',
        details: { kind: 'skipped', reason: 'blank_or_unsupported_intercom_part' }
      )

      get skip_logs_api_v1_account_data_import_url(account_id: account.id, id: data_import.id, format: :csv),
          headers: admin.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.body).to include('source_object_type,source_object_id')
      expect(response.body).to include('message,conversation:conversation_1:part:blank_part')
    end
  end
end
