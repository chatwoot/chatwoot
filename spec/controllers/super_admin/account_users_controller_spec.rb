require 'rails_helper'

RSpec.describe 'Super Admin Account Users API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/account_users/new' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/account_users/new'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      it 'shows the account user create page' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/account_users/new'
        expect(response).to have_http_status(:success)
      end

      it 'renders remote association selectors in the Super Admin field layout' do
        create(:account, name: 'Remote account')
        create(:user, name: 'Remote user')
        sign_in(super_admin, scope: :super_admin)

        get '/super_admin/account_users/new'

        document = Nokogiri::HTML(response.body)
        selectors = document.css('[data-field] select.js-belongs-to-search-field')
        expect(selectors.map { |select| select['name'] }).to eq(%w[account_user[account_id] account_user[user_id]])
        expect(selectors.map { |select| URI(select['data-url']).path }).to eq(%w[/super_admin/accounts.json /super_admin/users.json])
        expect(selectors.css('option').map { |option| option['value'] }.reject(&:blank?)).to be_empty
      end

      it 'returns remote account and user search results for the association selectors' do
        account = create(:account, name: 'Remote lookup account')
        user = create(:user, name: 'Remote lookup user')
        sign_in(super_admin, scope: :super_admin)

        get '/super_admin/accounts.json', params: { search: account.name }
        expect(response).to have_http_status(:success)
        expect(response.parsed_body['resources']).to eq([{ 'id' => account.id, 'dashboard_display_name' => "##{account.id} #{account.name}" }])

        get '/super_admin/users.json', params: { search: user.email }
        expect(response).to have_http_status(:success)
        expect(response.parsed_body['resources']).to eq([{ 'id' => user.id, 'dashboard_display_name' => "##{user.id} #{user.name}" }])
      end
    end
  end
end
