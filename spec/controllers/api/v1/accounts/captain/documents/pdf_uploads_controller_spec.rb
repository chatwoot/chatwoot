require 'rails_helper'

RSpec.describe Api::V1::Accounts::Captain::DocumentsController, type: :controller do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  before do
    sign_in(user)
  end

  describe 'POST #upload_pdf' do
    let(:pdf_file) do
      fixture_file_upload(
        Rails.root.join('spec', 'fixtures', 'files', 'sample.pdf'),
        'application/pdf'
      )
    end

    let(:valid_params) do
      {
        account_id: account.id,
        pdf_document: pdf_file,
        assistant_id: assistant.id
      }
    end

    context 'with valid parameters' do
      it 'creates a new document' do
        expect do
          post :upload_pdf, params: valid_params
        end.to change(Captain::Document, :count).by(1)
      end

      it 'returns success response' do
        post :upload_pdf, params: valid_params
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to have_key('document')
        expect(JSON.parse(response.body)).to have_key('message')
      end

      it 'sets document name from filename' do
        post :upload_pdf, params: valid_params
        document = Captain::Document.last
        expect(document.name).to eq('sample')
      end

      it 'sets document status to in_progress' do
        post :upload_pdf, params: valid_params
        document = Captain::Document.last
        expect(document.status).to eq('in_progress')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when assistant is missing' do
        params = valid_params.except(:assistant_id)
        post :upload_pdf, params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error when PDF file is missing' do
        params = valid_params.except(:pdf_document)
        post :upload_pdf, params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error when file is not a PDF' do
        txt_file = fixture_file_upload(
          Rails.root.join('spec', 'fixtures', 'files', 'sample.txt'),
          'text/plain'
        )
        params = valid_params.merge(pdf_document: txt_file)
        post :upload_pdf, params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error when file is too large' do
        # Mock large file size
        allow_any_instance_of(ActionDispatch::Http::UploadedFile).to receive(:size).and_return(11.megabytes)
        post :upload_pdf, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when document limit is exceeded' do
      before do
        allow_any_instance_of(Captain::Document).to receive(:save!).and_raise(
          Captain::Document::LimitExceededError, 'Document limit exceeded'
        )
      end

      it 'returns limit exceeded error' do
        post :upload_pdf, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['message']).to include('Document limit exceeded')
      end
    end
  end
end