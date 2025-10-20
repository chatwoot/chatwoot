require 'rails_helper'

RSpec.describe 'Appointments API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/appointments' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/appointments"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:contact) { create(:contact, account: account) }
      let!(:appointment) { create(:appointment, contact: contact) }

      it 'returns unauthorized for agents' do
        get "/api/v1/accounts/#{account.id}/appointments",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns all appointments to administrators' do
        get "/api/v1/accounts/#{account.id}/appointments",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body.first[:id]).to eq(appointment.id)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/appointments/:id' do
    let(:contact) { create(:contact, account: account) }
    let(:appointment) { create(:appointment, contact: contact) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/appointments/#{appointment.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agents' do
        get "/api/v1/accounts/#{account.id}/appointments/#{appointment.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'shows the appointment for administrators' do
        get "/api/v1/accounts/#{account.id}/appointments/#{appointment.id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:id]).to eq(appointment.id)
        expect(body[:contact]).to be_present
        expect(body[:contact][:id]).to eq(contact.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/appointments' do
    let(:contact) { create(:contact, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/appointments",
             params: { contact_id: contact.id, location: 'Office', description: 'Meeting', start_time: Time.zone.now, end_time: 1.hour.from_now },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agents' do
        post "/api/v1/accounts/#{account.id}/appointments",
             params: { contact_id: contact.id,
                       appointment: { location: 'Office', description: 'Meeting', start_time: Time.zone.now, end_time: 1.hour.from_now } },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new appointment' do
        start_time = Time.zone.now
        end_time = 1.hour.from_now

        post "/api/v1/accounts/#{account.id}/appointments",
             params: { contact_id: contact.id,
                       appointment: { location: 'Office', description: 'Meeting', start_time: start_time, end_time: end_time } },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:location]).to eq('Office')
        expect(body[:description]).to eq('Meeting')
        expect(body[:contact_id]).to eq(contact.id)
      end

      it 'returns error when end_time is before start_time' do
        start_time = Time.zone.now
        end_time = 1.hour.ago

        post "/api/v1/accounts/#{account.id}/appointments",
             params: { contact_id: contact.id,
                       appointment: { location: 'Office', description: 'Meeting', start_time: start_time, end_time: end_time } },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/appointments/:id' do
    let(:contact) { create(:contact, account: account) }
    let!(:appointment) { create(:appointment, contact: contact) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/appointments/#{appointment.id}",
              params: { appointment: { location: 'Home' } },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agents' do
        patch "/api/v1/accounts/#{account.id}/appointments/#{appointment.id}",
              params: { appointment: { location: 'Home' } },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'updates the appointment' do
        patch "/api/v1/accounts/#{account.id}/appointments/#{appointment.id}",
              params: { appointment: { location: 'Home', description: 'Updated meeting' } },
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:location]).to eq('Home')
        expect(body[:description]).to eq('Updated meeting')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/appointments/:id' do
    let(:contact) { create(:contact, account: account) }
    let!(:appointment) { create(:appointment, contact: contact) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/appointments/#{appointment.id}",
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'return unauthorized if agent' do
        delete "/api/v1/accounts/#{account.id}/appointments/#{appointment.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'delete appointment if admin' do
        delete "/api/v1/accounts/#{account.id}/appointments/#{appointment.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(Appointment.exists?(appointment.id)).to be false
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/appointments/validate_appointment_token' do
    let(:contact) { create(:contact, account: account) }
    let!(:appointment) { create(:appointment, contact: contact) }

    context 'when token is valid' do
      it 'returns valid true and contact_id' do
        post "/api/v1/accounts/#{account.id}/appointments/validate_appointment_token",
             params: { token: appointment.access_token },
             as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:valid]).to be true
        expect(body[:contact_id]).to eq(contact.id)
      end
    end

    context 'when token is invalid' do
      it 'returns valid false' do
        post "/api/v1/accounts/#{account.id}/appointments/validate_appointment_token",
             params: { token: 'invalid_token' },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:valid]).to be false
      end
    end

    context 'when token is not provided' do
      it 'returns valid false' do
        post "/api/v1/accounts/#{account.id}/appointments/validate_appointment_token",
             as: :json

        expect(response).to have_http_status(:unauthorized)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:valid]).to be false
      end
    end
  end
end
