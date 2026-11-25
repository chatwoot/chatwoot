require 'rails_helper'

# The dashboard builds its own text from the error type, so a 422 has to say which validation
# failed on which attribute, not only the joined English messages.
RSpec.describe 'A record invalid response', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:contact) { create(:contact, account: account, email: 'b960@example.com') }

  it 'sends the error type of each failing attribute' do
    create(:contact, account: account, email: 'a960@example.com', phone_number: '+5511999990000')

    patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
          headers: admin.create_new_auth_token,
          params: { email: 'a960@example.com', phone_number: '123' },
          as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    body = response.parsed_body
    expect(body['attributes']).to include('email', 'phone_number')
    expect(body['details']['email']).to include(include('error' => 'taken'))
    expect(body['details']['phone_number']).to include(include('error' => 'invalid'))
  end
end
