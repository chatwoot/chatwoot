require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::FaqImports', type: :request do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:base_path) { "/api/v1/accounts/#{account.id}/captain/assistants/#{assistant.id}/faq_imports" }

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  it 'uploads a valid CSV and returns a read-only preview' do
    create(:captain_assistant_response, assistant: assistant, question: 'Existing question', answer: 'Existing answer')

    expect do
      post base_path,
           params: { file: generate_csv_file([%w[Question Answer], ['Existing question', 'Imported answer'], ['', 'Missing']]) },
           headers: admin.create_new_auth_token
    end.to change(Captain::FaqImport, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(json_response).to include(row_count: 2, invalid_row_count: 1, status: 'preview')
    expect(json_response[:rows].first).to include(state: 'existing', existing_answer: 'Existing answer', resolution: 'skip')
  end

  it 'uploads UTF-8 CSV content received as binary' do
    file = Tempfile.new(['faqs', '.csv'])
    file.binmode
    file.write("question,answer\nWhat’s included?,Everything\n".b)
    file.rewind

    post base_path,
         params: { file: Rack::Test::UploadedFile.new(file.path, 'text/csv', true) },
         headers: admin.create_new_auth_token

    expect(response).to have_http_status(:created)
    expect(json_response[:rows].first).to include(question: 'What’s included?', answer: 'Everything', state: 'valid')
  ensure
    file&.close!
  end

  it 'rejects invalid headers and files over the row limit' do
    post base_path,
         params: { file: generate_csv_file([%w[question answer notes], %w[One Two Three]]) },
         headers: admin.create_new_auth_token
    expect(response).to have_http_status(:unprocessable_entity)

    oversized = [%w[question answer]] + Array.new(1001) { |index| ["Question #{index}", 'Answer'] }
    post base_path, params: { file: generate_csv_file(oversized) }, headers: admin.create_new_auth_token
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'rejects a file over the configured upload limit before reading it' do
    allow(GlobalConfigService).to receive(:load).with('MAXIMUM_FILE_UPLOAD_SIZE', 40).and_return('1')
    file = generate_csv_file([%w[question answer], ['Question', 'A' * 1.megabyte]])

    expect do
      post base_path, params: { file: file }, headers: admin.create_new_auth_token
    end.not_to change(Captain::FaqImport, :count)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json_response).to include(error: 'File exceeds the maximum allowed size')
  end

  it 'does not allow an agent to preview an import' do
    post base_path,
         params: { file: generate_csv_file([%w[question answer], %w[One Two]]) },
         headers: agent.create_new_auth_token

    expect(response).to have_http_status(:unauthorized)
  end

  it 'allows only one preparing import per assistant' do
    create(:captain_faq_import, assistant: assistant, account: account, user: admin, status: :preparing, confirmed_at: Time.current)

    post base_path,
         params: { file: generate_csv_file([%w[question answer], %w[One Two]]) },
         headers: admin.create_new_auth_token

    expect(response).to have_http_status(:conflict)
  end

  it 'rechecks for a preparing import while replacing a preview' do
    use_assistant_instance
    allow(assistant).to receive(:with_lock).and_wrap_original do |method, *args, &block|
      create(
        :captain_faq_import,
        assistant: method.receiver,
        account: account,
        user: admin,
        status: :preparing,
        confirmed_at: Time.current
      )
      method.call(*args, &block)
    end

    post base_path,
         params: { file: generate_csv_file([%w[question answer], %w[One Two]]) },
         headers: admin.create_new_auth_token

    expect(response).to have_http_status(:conflict)
    expect(assistant.faq_imports.pluck(:status)).to eq(['preparing'])
  end

  it 'confirms overwrite choices and returns only the latest confirmed status' do
    existing = create(:captain_assistant_response, assistant: assistant, question: 'Existing question', answer: 'Existing answer')
    rows = Captain::FaqImports::Parser.new(
      assistant: assistant,
      content: "question,answer\nExisting question,Imported answer\n"
    ).perform
    faq_import = create(:captain_faq_import, assistant: assistant, account: account, user: admin, rows: rows, row_count: 1)

    expect do
      post "#{base_path}/#{faq_import.id}/confirm",
           params: { overwrite_row_numbers: [2] },
           headers: admin.create_new_auth_token,
           as: :json
    end.to have_enqueued_job(Captain::FaqImports::ProcessJob).with(faq_import)

    expect(response).to have_http_status(:accepted)
    expect(faq_import.reload.rows.first['resolution']).to eq('overwrite')

    get "#{base_path}/latest", headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:ok)
    expect(json_response).to include(id: faq_import.id, status: 'preparing')
    expect(existing.reload.answer).to eq('Existing answer')
  end

  it 'does not confirm a preview that was replaced while waiting for the assistant lock' do
    faq_import = create(:captain_faq_import, assistant: assistant, account: account, user: admin)
    use_assistant_instance
    allow(assistant).to receive(:with_lock).and_wrap_original do |method, *args, &block|
      faq_import.destroy! if faq_import.persisted?
      method.call(*args, &block)
    end

    expect do
      post "#{base_path}/#{faq_import.id}/confirm",
           params: { overwrite_row_numbers: [] },
           headers: admin.create_new_auth_token,
           as: :json
    end.not_to have_enqueued_job(Captain::FaqImports::ProcessJob)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(json_response).to include(error: 'This import can no longer be confirmed.')
  end

  it 'queues recovery when the latest import has stopped making progress' do
    faq_import = create(
      :captain_faq_import,
      assistant: assistant,
      account: account,
      user: admin,
      status: :preparing,
      confirmed_at: 20.minutes.ago,
      updated_at: 20.minutes.ago,
      row_count: 1,
      rows: [{ 'state' => Captain::FaqImport::ROW_STATES[:valid] }]
    )

    expect do
      get "#{base_path}/latest", headers: admin.create_new_auth_token, as: :json
    end.to have_enqueued_job(Captain::FaqImports::RecoverStalledJob)

    expect(response).to have_http_status(:ok)
    expect(json_response).to include(id: faq_import.id, status: 'preparing')

    expect do
      perform_enqueued_jobs(only: Captain::FaqImports::RecoverStalledJob)
    end.to have_enqueued_job(Captain::FaqImports::ProcessJob).with(faq_import)
  end

  it 'claims stalled recovery before queuing a job' do
    faq_import = create(
      :captain_faq_import,
      assistant: assistant,
      account: account,
      user: admin,
      status: :preparing,
      confirmed_at: 20.minutes.ago,
      updated_at: 20.minutes.ago
    )

    expect do
      2.times { get "#{base_path}/latest", headers: admin.create_new_auth_token, as: :json }
    end.to have_enqueued_job(Captain::FaqImports::RecoverStalledJob).exactly(:once)

    expect(faq_import.reload.updated_at).to be_within(5.seconds).of(Time.current)
  end

  it 'downloads invalid rows with a clear error column' do
    rows = Captain::FaqImports::Parser.new(assistant: assistant, content: "question,answer\n,Missing question\n").perform
    faq_import = create(:captain_faq_import, assistant: assistant, account: account, user: admin, rows: rows, row_count: 1)

    get "#{base_path}/#{faq_import.id}/invalid_rows", headers: admin.create_new_auth_token

    expect(response).to have_http_status(:ok)
    expect(CSV.parse(response.body)).to eq(
      [['question', 'answer', 'error'], ['', 'Missing question', 'Question is required.']]
    )
  end

  it 'neutralizes spreadsheet formulas in downloaded invalid rows' do
    content = CSV.generate do |csv|
      csv << %w[question answer]
      csv << ['=1+1', '']
      csv << ['', '@SUM(1,1)']
    end
    rows = Captain::FaqImports::Parser.new(assistant: assistant, content: content).perform
    faq_import = create(:captain_faq_import, assistant: assistant, account: account, user: admin, rows: rows, row_count: 2)

    get "#{base_path}/#{faq_import.id}/invalid_rows", headers: admin.create_new_auth_token

    expect(response).to have_http_status(:ok)
    expect(CSV.parse(response.body)).to eq(
      [
        %w[question answer error],
        ["'=1+1", '', 'Answer is required.'],
        ['', "'@SUM(1,1)", 'Question is required.']
      ]
    )
  end

  def use_assistant_instance
    allow(Current).to receive(:account).and_return(account)
    allow(account.captain_assistants).to receive(:find).and_return(assistant)
  end
end
