require 'rails_helper'

RSpec.describe 'Data Imports API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:validator) { instance_double(DataImports::Intercom::CredentialsValidator, perform: { 'contacts' => 12, 'conversations' => 8 }) }

  before do
    account.enable_features!('data_import')
    allow(DataImports::Intercom::CredentialsValidator).to receive(:new).and_return(validator)
  end

  describe 'POST /api/v1/accounts/:account_id/data_imports/validate_source' do
    it 'validates the selected Intercom source and returns discovered totals' do
      post validate_source_api_v1_account_data_imports_url(account_id: account.id),
           params: {
             source_provider: 'intercom', access_token: 'intercom-token', import_types: %w[contacts conversations]
           },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq('valid' => true, 'totals' => { 'contacts' => 12, 'conversations' => 8 })
    end

    it 'returns a safe validation error' do
      allow(validator).to receive(:perform).and_raise(DataImports::Intercom::Client::AuthenticationError, 'provider response')

      post validate_source_api_v1_account_data_imports_url(account_id: account.id),
           params: { source_provider: 'intercom', access_token: 'invalid', import_types: %w[contacts] },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq(
        'valid' => false,
        'message' => 'We could not validate this Intercom access key. Check the key and its permissions.'
      )
    end
  end

  describe 'POST /api/v1/accounts/:account_id/data_imports' do
    it 'returns unauthorized and does not enqueue imports when data import is disabled' do
      account.disable_features!('data_import')

      expect do
        post api_v1_account_data_imports_url(account_id: account.id),
             params: {
               name: 'Migration run', source_provider: 'intercom', access_token: 'intercom-token',
               import_types: %w[contacts conversations]
             },
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to have_enqueued_job(DataImports::Intercom::ImportJob)

      expect(response).to have_http_status(:unauthorized)
      expect(account.data_imports).to be_empty
    end

    it 'creates and enqueues an Intercom import', :aggregate_failures do
      expect do
        post api_v1_account_data_imports_url(account_id: account.id),
             params: {
               name: 'Migration run', source_provider: 'intercom', access_token: 'intercom-token',
               import_types: %w[contacts conversations]
             },
             headers: admin.create_new_auth_token,
             as: :json
      end.to have_enqueued_job(DataImports::Intercom::ImportJob)

      expect(response).to have_http_status(:ok)
      data_import = account.data_imports.last
      expect(data_import).to have_attributes(
        name: 'Migration run',
        data_type: 'intercom',
        source_type: 'api',
        source_provider: 'intercom',
        initiated_by_id: admin.id
      )
      expect(data_import.access_token).to eq('intercom-token')
      expect(data_import.import_types).to eq(%w[contacts conversations])
      expect(data_import.stats).to include(
        'contacts' => include('total' => 12),
        'conversations' => include('total' => 8)
      )
      expect(response.parsed_body['source_provider']).to eq('intercom')
      expect(response.parsed_body).not_to have_key('access_token')
    end

    it 'rejects creation while another Intercom import is active' do
      active_import = create(
        :data_import, :intercom,
        account: account,
        status: :processing
      )

      expect do
        post api_v1_account_data_imports_url(account_id: account.id),
             params: {
               name: 'Second run', source_provider: 'intercom', access_token: 'intercom-token',
               import_types: %w[contacts conversations]
             },
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to have_enqueued_job(DataImports::Intercom::ImportJob)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq('Another data import is already in progress.')
      expect(account.data_imports.where(data_type: 'intercom', source_provider: 'intercom').count).to eq(1)
      expect(active_import.reload).to be_processing
    end

    it 'rejects unsupported import types instead of silently importing everything' do
      allow(validator).to receive(:perform).and_raise(ArgumentError, 'Unsupported import types: companies')

      expect do
        post api_v1_account_data_imports_url(account_id: account.id),
             params: {
               name: 'Migration run', source_provider: 'intercom', access_token: 'intercom-token', import_types: %w[companies]
             },
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to have_enqueued_job(DataImports::Intercom::ImportJob)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq('Unsupported import types: companies')
      expect(account.data_imports).to be_empty
    end
  end

  describe 'POST /api/v1/accounts/:account_id/data_imports/:id/start' do
    let(:data_import) { create(:data_import, :intercom, account: account) }

    it 'restarts abandoned imports' do
      data_import.update!(
        status: :abandoned,
        abandoned_at: 1.hour.ago,
        source_metadata: { DataImport::ACTIVE_INTERCOM_IMPORT_RUN_ID_KEY => 'previous-run' }
      )
      data_import.import_errors.create!(
        error_code: 'StandardError',
        message: 'old run error',
        details: { kind: 'run_error' }
      )
      data_import.import_errors.create!(
        error_code: DataImports::Intercom::Importer::ALREADY_IMPORTED_ERROR_CODE,
        message: 'old skip log',
        details: { kind: 'skipped' }
      )

      expect do
        post start_api_v1_account_data_import_url(account_id: account.id, id: data_import.id),
             headers: admin.create_new_auth_token,
             as: :json
      end.to have_enqueued_job(DataImports::Intercom::ImportJob).with(data_import, a_kind_of(String))

      expect(response).to have_http_status(:ok)
      expect(data_import.reload).to be_pending
      expect(data_import.abandoned_at).to be_nil
      expect(data_import.started_at).to be_nil
      expect(data_import.active_intercom_import_run_id).not_to eq('previous-run')
      expect(data_import.import_errors.pluck(:error_code)).to eq([DataImports::Intercom::Importer::ALREADY_IMPORTED_ERROR_CODE])
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
        :data_import, :intercom,
        account: account,
        status: :processing
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

    it 'does not restart imports when the stored access key is unavailable' do
      data_import.update!(status: :abandoned, abandoned_at: 1.hour.ago, access_token: nil)

      expect do
        post start_api_v1_account_data_import_url(account_id: account.id, id: data_import.id),
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to have_enqueued_job(DataImports::Intercom::ImportJob)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq('The Intercom access key for this import is unavailable.')
      expect(data_import.reload).to be_abandoned
    end
  end

  describe 'POST /api/v1/accounts/:account_id/data_imports/:id/abandon' do
    let(:data_import) { create(:data_import, :intercom, account: account) }

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

    it 'does not abandon legacy contact imports' do
      legacy_import = create(:data_import, account: account, status: :processing)

      post abandon_api_v1_account_data_import_url(account_id: account.id, id: legacy_import.id),
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(legacy_import.reload).to be_processing
      expect(legacy_import.abandoned_at).to be_nil
    end
  end

  describe 'GET /api/v1/accounts/:account_id/data_imports/:id' do
    let(:data_import) do
      create(
        :data_import, :intercom,
        account: account,
        name: 'July Intercom migration',
        initiated_by: admin
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

    it 'returns the latest five skip logs' do
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

      get api_v1_account_data_import_url(account_id: account.id, id: data_import.id),
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['skip_logs'].pluck('source_object_id')).to eq(%w[message_15 message_14 message_13 message_12 message_11])
      expect(response.parsed_body).not_to have_key('skip_logs_pagination')
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
      expect(response.parsed_body['skip_logs_filters']).to include(
        'selected_source_object_type' => 'contact',
        'counts_by_type' => include('contact' => 3, 'message' => 2)
      )
    end

    it 'returns the latest five error logs' do
      16.times do |index|
        data_import.import_errors.create!(
          error_code: 'Intercom::RateLimited',
          message: 'Rate limited',
          source_object_type: 'conversation',
          source_object_id: "conversation_#{index}",
          created_at: Time.zone.at(index)
        )
      end

      get api_v1_account_data_import_url(account_id: account.id, id: data_import.id),
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['import_errors'].pluck('source_object_id')).to eq(
        %w[conversation_15 conversation_14 conversation_13 conversation_12 conversation_11]
      )
      expect(response.parsed_body).not_to have_key('import_errors_pagination')
    end
  end

  describe 'GET /api/v1/accounts/:account_id/data_imports/:id/error_logs.csv' do
    let(:data_import) do
      create(
        :data_import, :intercom,
        account: account,
        initiated_by: admin
      )
    end

    it 'downloads all error logs as CSV' do
      6.times do |index|
        data_import.import_errors.create!(
          error_code: 'Intercom::RateLimited',
          message: 'Rate limited',
          source_object_type: 'conversation',
          source_object_id: "conversation_#{index}",
          details: { kind: 'run_error' }
        )
      end

      get error_logs_api_v1_account_data_import_url(account_id: account.id, id: data_import.id, format: :csv),
          headers: admin.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.body).to include('source_object_type,source_object_id')
      expect(response.body).to include('conversation,conversation_0,Intercom::RateLimited,Rate limited')
      expect(response.body).to include('conversation,conversation_5,Intercom::RateLimited,Rate limited')
      expect(response.body.lines.size).to eq(7)
    end
  end

  describe 'GET /api/v1/accounts/:account_id/data_imports/:id/skip_logs.csv' do
    let(:data_import) do
      create(
        :data_import, :intercom,
        account: account,
        initiated_by: admin
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
