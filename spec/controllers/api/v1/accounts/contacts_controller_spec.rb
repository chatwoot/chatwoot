require 'rails_helper'

RSpec.describe 'Contacts API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/contacts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let!(:contact) { create(:contact, :with_email, account: account, additional_attributes: { company_name: 'Company 1', country_code: 'IN' }) }
      let!(:contact_1) do
        create(:contact, :with_email, account: account, additional_attributes: { company_name: 'Test Company 1', country_code: 'CA' })
      end
      let(:contact_2) do
        create(:contact, :with_email, account: account, additional_attributes: { company_name: 'Marvel Company', country_code: 'AL' })
      end
      let(:contact_3) do
        create(:contact, :with_email, account: account, additional_attributes: { company_name: nil, country_code: nil })
      end
      let!(:contact_4) do
        create(:contact, :with_email, account: account, additional_attributes: { company_name: nil, country_code: nil })
      end
      let!(:contact_inbox) { create(:contact_inbox, contact: contact) }

      it 'returns all resolved contacts along with contact inboxes' do
        get "/api/v1/accounts/#{account.id}/contacts",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)
        expect(response_body['payload'].first['email']).to eq(contact.email)
        expect(response_body['payload'].first['contact_inboxes'].first['source_id']).to eq(contact_inbox.source_id)
        expect(response_body['payload'].first['contact_inboxes'].first['inbox']['name']).to eq(contact_inbox.inbox.name)
      end

      it 'returns all contacts without contact inboxes' do
        get "/api/v1/accounts/#{account.id}/contacts?include_contact_inboxes=false",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)
        expect(response_body['payload'].first['email']).to eq(contact.email)
        expect(response_body['payload'].first['contact_inboxes'].blank?).to eq(true)
      end

      it 'returns all contacts with company name desc order' do
        get "/api/v1/accounts/#{account.id}/contacts?include_contact_inboxes=false&sort=-company",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)
        expect(response_body['payload'].last['id']).to eq(contact_4.id)
        expect(response_body['payload'].last['email']).to eq(contact_4.email)
      end

      it 'returns all contacts with company name asc order with null values at last' do
        get "/api/v1/accounts/#{account.id}/contacts?include_contact_inboxes=false&sort=-company",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)
        expect(response_body['payload'].first['email']).to eq(contact_1.email)
        expect(response_body['payload'].first['id']).to eq(contact_1.id)
        expect(response_body['payload'].last['email']).to eq(contact_4.email)
      end

      it 'returns all contacts with country name desc order with null values at last' do
        get "/api/v1/accounts/#{account.id}/contacts?include_contact_inboxes=false&sort=country",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)
        expect(response_body['payload'].first['email']).to eq(contact.email)
        expect(response_body['payload'].first['id']).to eq(contact.id)
        expect(response_body['payload'].last['email']).to eq(contact_4.email)
      end

      it 'returns includes conversations count and last seen at' do
        create(:conversation, contact: contact, account: account, inbox: contact_inbox.inbox, contact_last_seen_at: Time.now.utc)
        get "/api/v1/accounts/#{account.id}/contacts",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)
        expect(response_body['payload'].first['conversations_count']).to eq(contact.conversations.count)
        expect(response_body['payload'].first['last_seen_at']).present?
      end

      it 'filters resolved contacts based on label filter' do
        contact_with_label1, contact_with_label2 = FactoryBot.create_list(:contact, 2, :with_email, account: account)
        contact_with_label1.update_labels(['label1'])
        contact_with_label2.update_labels(['label2'])

        get "/api/v1/accounts/#{account.id}/contacts",
            params: { labels: %w[label1 label2] },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)
        expect(response_body['meta']['count']).to eq(2)
        expect(response_body['payload'].pluck('email')).to include(contact_with_label1.email, contact_with_label2.email)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/import' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/contacts/import"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with out permission' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/contacts/import",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'creates a data import' do
        file = fixture_file_upload(Rails.root.join('spec/assets/contacts.csv'), 'text/csv')
        post "/api/v1/accounts/#{account.id}/contacts/import",
             headers: admin.create_new_auth_token,
             params: { import_file: file }

        expect(response).to have_http_status(:success)
        expect(account.data_imports.count).to eq(1)
        expect(account.data_imports.first.import_file.attached?).to eq(true)
      end
    end

    context 'when file is empty' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns Unprocessable Entity' do
        post "/api/v1/accounts/#{account.id}/contacts/import",
             headers: admin.create_new_auth_token

        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('File is blank')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/active' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/active"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let!(:contact) { create(:contact, account: account) }

      it 'returns no contacts if no are online' do
        get "/api/v1/accounts/#{account.id}/contacts/active",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include(contact.name)
      end

      it 'returns all contacts who are online' do
        allow(::OnlineStatusTracker).to receive(:get_available_contact_ids).and_return([contact.id])

        get "/api/v1/accounts/#{account.id}/contacts/active",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact.name)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/search' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/search"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let!(:contact1) { create(:contact, :with_email, account: account) }
      let!(:contact2) { create(:contact, :with_email, name: 'testcontact', account: account, email: 'test@test.com') }

      it 'returns all resolved contacts with contact inboxes' do
        get "/api/v1/accounts/#{account.id}/contacts/search",
            params: { q: contact2.email },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact2.email)
        expect(response.body).not_to include(contact1.email)
      end

      it 'matches the contact ignoring the case in email' do
        get "/api/v1/accounts/#{account.id}/contacts/search",
            params: { q: 'Test@Test.com' },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact2.email)
        expect(response.body).not_to include(contact1.email)
      end

      it 'matches the contact ignoring the case in name' do
        get "/api/v1/accounts/#{account.id}/contacts/search",
            params: { q: 'TestContact' },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact2.email)
        expect(response.body).not_to include(contact1.email)
      end

      it 'matches the resolved contact respecting the identifier character casing' do
        contact_normal = create(:contact, name: 'testcontact', account: account, identifier: 'testidentifer')
        contact_special = create(:contact, name: 'testcontact', account: account, identifier: 'TestIdentifier')
        get "/api/v1/accounts/#{account.id}/contacts/search",
            params: { q: 'TestIdentifier' },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact_special.identifier)
        expect(response.body).not_to include(contact_normal.identifier)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/filter' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/filter"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let!(:contact1) { create(:contact, :with_email, account: account) }
      let!(:contact2) { create(:contact, :with_email, name: 'testcontact', account: account, email: 'test@test.com') }

      it 'returns all contacts when query is empty' do
        post "/api/v1/accounts/#{account.id}/contacts/filter",
             params: {
               payload: []
             },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact2.email)
        expect(response.body).to include(contact1.email)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/:id' do
    let!(:contact) { create(:contact, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'shows the contact' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact.name)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/:id/contactable_inboxes' do
    let!(:contact) { create(:contact, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/contactable_inboxes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let!(:twilio_sms) { create(:channel_twilio_sms, account: account) }
      let!(:twilio_sms_inbox) { create(:inbox, channel: twilio_sms, account: account) }
      let!(:twilio_whatsapp) { create(:channel_twilio_sms, medium: :whatsapp, account: account) }
      let!(:twilio_whatsapp_inbox) { create(:inbox, channel: twilio_whatsapp, account: account) }

      it 'shows the contactable inboxes which the user has access to' do
        create(:inbox_member, user: agent, inbox: twilio_whatsapp_inbox)

        inbox_service = double
        allow(Contacts::ContactableInboxesService).to receive(:new).and_return(inbox_service)
        allow(inbox_service).to receive(:get).and_return([
                                                           { source_id: '1123', inbox: twilio_sms_inbox },
                                                           { source_id: '1123', inbox: twilio_whatsapp_inbox }
                                                         ])
        expect(inbox_service).to receive(:get)
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/contactable_inboxes",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        # only the inboxes which agent has access to are shown
        expect(JSON.parse(response.body)['payload'].pluck('inbox').pluck('id')).to eq([twilio_whatsapp_inbox.id])
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts' do
    let(:custom_attributes) { { test: 'test', test1: 'test1' } }
    let(:valid_params) { { name: 'test', custom_attributes: custom_attributes } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/contacts", params: valid_params }.to change(Contact, :count).by(0)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:inbox) { create(:inbox, account: account) }

      it 'creates the contact' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts", headers: admin.create_new_auth_token,
                                                          params: valid_params
        end.to change(Contact, :count).by(1)

        expect(response).to have_http_status(:success)

        # custom attributes are updated
        json_response = JSON.parse(response.body)
        expect(json_response['payload']['contact']['custom_attributes']).to eq({ 'test' => 'test', 'test1' => 'test1' })
      end

      it 'does not create the contact' do
        valid_params[:name] = 'test' * 999

        post "/api/v1/accounts/#{account.id}/contacts", headers: admin.create_new_auth_token,
                                                        params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Name is too long (maximum is 255 characters)')
      end

      it 'creates the contact inbox when inbox id is passed' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts", headers: admin.create_new_auth_token,
                                                          params: valid_params.merge({ inbox_id: inbox.id })
        end.to change(ContactInbox, :count).by(1)

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/contacts/:id' do
    let(:custom_attributes) { { test: 'test', test1: 'test1' } }
    let!(:contact) { create(:contact, account: account, custom_attributes: custom_attributes) }
    let(:valid_params) { { name: 'Test Blub', custom_attributes: { test: 'new test', test2: 'test2' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
            params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'updates the contact' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(contact.reload.name).to eq('Test Blub')
        # custom attributes are merged properly without overwriting existing ones
        expect(contact.custom_attributes).to eq({ 'test' => 'new test', 'test1' => 'test1', 'test2' => 'test2' })
      end

      it 'prevents the update of contact of another account' do
        other_account = create(:account)
        other_contact = create(:contact, account: other_account)

        patch "/api/v1/accounts/#{account.id}/contacts/#{other_contact.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'prevents updating with an existing email' do
        other_contact = create(:contact, account: account, email: 'test1@example.com')

        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
              headers: admin.create_new_auth_token,
              params: valid_params.merge({ email: other_contact.email }),
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['attributes']).to include('email')
      end

      it 'prevents updating with an existing phone number' do
        other_contact = create(:contact, account: account, phone_number: '+12000000')

        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
              headers: admin.create_new_auth_token,
              params: valid_params.merge({ phone_number: other_contact.phone_number }),
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['attributes']).to include('phone_number')
      end

      it 'updates avatar' do
        # no avatar before upload
        expect(contact.avatar.attached?).to eq(false)
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
              params: valid_params.merge(avatar: file),
              headers: admin.create_new_auth_token

        expect(response).to have_http_status(:success)
        contact.reload
        expect(contact.avatar.attached?).to eq(true)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/contacts/:id', :contact_delete do
    let(:inbox) { create(:inbox, account: account) }
    let(:contact) { create(:contact, account: account) }
    let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/contacts/#{contact.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'deletes the contact for administrator user' do
        allow(::OnlineStatusTracker).to receive(:get_presence).and_return(false)
        delete "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
               headers: admin.create_new_auth_token

        expect(contact.conversations).to be_empty
        expect(contact.inboxes).to be_empty
        expect(contact.contact_inboxes).to be_empty
        expect(contact.csat_survey_responses).to be_empty
        expect { contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to have_http_status(:success)
      end

      it 'does not delete the contact if online' do
        allow(::OnlineStatusTracker).to receive(:get_presence).and_return(true)

        delete "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
               headers: admin.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns unauthorized for agent user' do
        delete "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
               headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts/:id/destroy_custom_attributes' do
    let(:custom_attributes) { { test: 'test', test1: 'test1' } }
    let!(:contact) { create(:contact, account: account, custom_attributes: custom_attributes) }
    let(:valid_params) { { custom_attributes: ['test'] } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/destroy_custom_attributes",
             params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'delete the custom attribute' do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/destroy_custom_attributes",
             headers: admin.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(contact.reload.custom_attributes).to eq({ 'test1' => 'test1' })
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/contacts/:id/avatar' do
    let(:contact) { create(:contact, account: account) }
    let(:agent) { create(:user, account: account, role: :agent) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/avatar"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        create(:contact, account: account)
        contact.avatar.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
      end

      it 'delete contact avatar' do
        delete "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/avatar",
               headers: agent.create_new_auth_token,
               as: :json

        expect { contact.avatar.attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
