require 'rails_helper'

RSpec.describe 'Canned Responses API', type: :request do
  let(:account) { create(:account) }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: Rails.root.join('spec/assets/sample.pdf').open,
      filename: 'sample.pdf',
      content_type: 'application/pdf'
    )
  end

  before do
    create(:canned_response, account: account, content: 'Hey {{ contact.name }}, Thanks for reaching out', short_code: 'name-short-code')
  end

  describe 'GET /api/v1/accounts/{account.id}/canned_responses' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/canned_responses"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all the canned responses' do
        get "/api/v1/accounts/#{account.id}/canned_responses",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to eq(account.canned_responses.as_json.map { |canned_response| canned_response.merge('files' => []) })
      end

      it 'returns the files attached to a canned response' do
        canned_response = account.canned_responses.first
        canned_response.files.attach(blob)

        get "/api/v1/accounts/#{account.id}/canned_responses",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response.parsed_body.first['files']).to eq(
          [{
            'signed_id' => blob.signed_id,
            'filename' => 'sample.pdf',
            'content_type' => 'application/pdf',
            'byte_size' => blob.byte_size,
            'file_url' => rails_blob_url(blob)
          }]
        )
      end

      it 'returns all the canned responses the user searched for' do
        cr1 = account.canned_responses.first
        create(:canned_response, account: account, content: 'Great! Looking forward', short_code: 'short-code')
        cr2 = create(:canned_response, account: account, content: 'Thanks for reaching out', short_code: 'content-with-thanks')
        cr3 = create(:canned_response, account: account, content: 'Thanks for reaching out', short_code: 'Thanks')

        params = { search: 'thanks' }

        get "/api/v1/accounts/#{account.id}/canned_responses",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.pluck('id')).to eq([cr3, cr2, cr1].map(&:id))
      end

      it 'ignores null bytes in the search string' do
        matching_response = create(:canned_response, account: account, content: 'Unique response', short_code: 'unique')

        get "/api/v1/accounts/#{account.id}/canned_responses",
            params: { search: "uni\0que" },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.pluck('id')).to eq([matching_response.id])
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/canned_responses' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/canned_responses"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'creates a new canned response' do
        params = { short_code: 'short', content: 'content' }

        post "/api/v1/accounts/#{account.id}/canned_responses",
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(account.canned_responses.count).to eq(2)
      end

      it 'attaches the uploaded files to the canned response' do
        post "/api/v1/accounts/#{account.id}/canned_responses",
             params: { short_code: 'guide', content: 'Here is the guide', files: [blob.signed_id] },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(account.canned_responses.find_by(short_code: 'guide').files.blobs).to eq([blob])
        expect(response.parsed_body['files'].pluck('signed_id')).to eq([blob.signed_id])
      end

      it 'does not create the canned response when a file id is invalid' do
        post "/api/v1/accounts/#{account.id}/canned_responses",
             params: { short_code: 'guide', content: 'Here is the guide', files: ['invalid'] },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(account.canned_responses.count).to eq(1)
      end

      it 'does not create the canned response when a file id is not a string' do
        post "/api/v1/accounts/#{account.id}/canned_responses",
             params: { short_code: 'guide', content: 'Here is the guide', files: [123] },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(account.canned_responses.count).to eq(1)
      end

      it 'does not create the canned response with more files than a message can carry' do
        signed_ids = Array.new(Message::NUMBER_OF_PERMITTED_ATTACHMENTS + 1) do |index|
          ActiveStorage::Blob.create_and_upload!(io: StringIO.new('notes'), filename: "notes-#{index}.txt", content_type: 'text/plain').signed_id
        end

        post "/api/v1/accounts/#{account.id}/canned_responses",
             params: { short_code: 'guide', content: 'Here is the guide', files: signed_ids },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to eq('Files cannot be more than 15')
        expect(account.canned_responses.count).to eq(1)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/canned_responses/:id' do
    let(:canned_response) { CannedResponse.last }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'updates an existing canned response' do
        params = { short_code: 'B' }

        put "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(canned_response.reload.short_code).to eq('B')
      end

      context 'when the canned response has a file' do
        let(:new_blob) do
          ActiveStorage::Blob.create_and_upload!(
            io: Rails.root.join('spec/assets/sample.png').open,
            filename: 'sample.png',
            content_type: 'image/png'
          )
        end

        before do
          canned_response.files.attach(blob)
        end

        it 'keeps the file when the request does not mention files' do
          put "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
              params: { short_code: 'B' },
              headers: agent.create_new_auth_token,
              as: :json

          expect(canned_response.reload.files.blobs).to eq([blob])
        end

        it 'replaces the files with the listed ones' do
          put "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
              params: { content: 'Updated', files: [new_blob.signed_id] },
              headers: agent.create_new_auth_token,
              as: :json

          expect(canned_response.reload.files.blobs).to eq([new_blob])
        end

        it 'removes every file when the request sends an empty list' do
          put "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
              params: { content: 'Updated', files: [] },
              headers: agent.create_new_auth_token,
              as: :json

          expect(canned_response.reload.files).to be_empty
        end
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/canned_responses/:id' do
    let(:canned_response) { CannedResponse.last }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'destroys the canned response' do
        delete "/api/v1/accounts/#{account.id}/canned_responses/#{canned_response.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(CannedResponse.count).to eq(0)
      end
    end
  end
end
