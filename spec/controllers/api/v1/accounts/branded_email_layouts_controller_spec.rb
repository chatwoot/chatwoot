require 'rails_helper'

RSpec.describe 'Branded Email Layout API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:layout) { '<html><body><header>Brand</header>{{ content_for_layout }}</body></html>' }

  describe 'GET /api/v1/accounts/{account.id}/branded_email_layout' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/branded_email_layout"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/branded_email_layout",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      it 'returns the account-scoped branded email layout' do
        create(:email_template, :layout, account: account, body: layout)

        get "/api/v1/accounts/#{account.id}/branded_email_layout",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['branded_email_layout']).to eq(layout)
      end

      it 'returns null when no account-scoped layout exists' do
        get "/api/v1/accounts/#{account.id}/branded_email_layout",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['branded_email_layout']).to be_nil
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/branded_email_layout' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/branded_email_layout",
              params: { branded_email_layout: layout },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/branded_email_layout",
              headers: agent.create_new_auth_token,
              params: { branded_email_layout: layout },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      it 'updates account-scoped branded email layout when feature is enabled' do
        account.enable_features!(:branded_email_templates)

        patch "/api/v1/accounts/#{account.id}/branded_email_layout",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: layout },
              as: :json

        template = EmailTemplate.account_branded_layout_template_for(account)
        expect(response).to have_http_status(:success)
        expect(template.body).to eq(layout)
        expect(response.parsed_body['branded_email_layout']).to eq(layout)
      end

      it 'clears account-scoped branded email layout when blank value is passed' do
        account.enable_features!(:branded_email_templates)
        create(:email_template, :layout, account: account, body: layout)

        patch "/api/v1/accounts/#{account.id}/branded_email_layout",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: '' },
              as: :json

        expect(response).to have_http_status(:success)
        expect(EmailTemplate.account_branded_layout_template_for(account)).to be_nil
        expect(response.parsed_body['branded_email_layout']).to be_nil
      end

      it 'clears account-scoped branded email layout when null string is passed' do
        account.enable_features!(:branded_email_templates)
        create(:email_template, :layout, account: account, body: layout)

        patch "/api/v1/accounts/#{account.id}/branded_email_layout",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: 'null' },
              as: :json

        expect(response).to have_http_status(:success)
        expect(EmailTemplate.account_branded_layout_template_for(account)).to be_nil
        expect(response.parsed_body['branded_email_layout']).to be_nil
      end

      it 'rejects updates when feature is disabled' do
        patch "/api/v1/accounts/#{account.id}/branded_email_layout",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: layout },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Branded email templates feature is not enabled')
        expect(EmailTemplate.account_branded_layout_template_for(account)).to be_nil
      end

      it 'rejects account-scoped branded email layout without content slot' do
        account.enable_features!(:branded_email_templates)

        patch "/api/v1/accounts/#{account.id}/branded_email_layout",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: '<html>No slot</html>' },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('must include {{ content_for_layout }}')
      end

      it 'rejects account-scoped branded email layout with invalid liquid syntax' do
        account.enable_features!(:branded_email_templates)

        patch "/api/v1/accounts/#{account.id}/branded_email_layout",
              headers: admin.create_new_auth_token,
              params: { branded_email_layout: '<html>{{ content_for_layout }} {{ broken </html>' },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('has invalid Liquid syntax')
      end
    end
  end
end
