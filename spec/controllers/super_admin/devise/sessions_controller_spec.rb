require 'rails_helper'
require 'climate_control'

RSpec.describe SuperAdmin::Devise::SessionsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:devise_mapping) { Devise.mappings[:super_admin] }

  before do
    # Explicitly set Devise which Devise mapping to use
    request.env['devise.mapping'] = devise_mapping
  end

  describe '#new' do
    it 'renders the login page' do
      with_modified_env LOGRAGE_ENABLED: 'true' do
        get :new
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#create' do
    let(:super_admin) { create(:super_admin) }

    context 'with valid credentials' do
      it 'signs in the super admin and redirects to super admin users page' do
        with_modified_env LOGRAGE_ENABLED: 'false' do
          post :create, params: { super_admin: { email: super_admin.email, password: super_admin.password } }
          expect(response).to redirect_to(super_admin_users_path)
          expect(flash[:error]).to be_nil
        end
      end
    end

    context 'with invalid credentials' do
      it 'redirects to login page with error message' do
        with_modified_env LOGRAGE_ENABLED: 'true' do
          post :create, params: { super_admin: { email: super_admin.email, password: 'wrongpassword' } }
          expect(response).to redirect_to(super_admin_session_path)
          expect(flash[:error]).not_to be_nil
        end
      end
    end
  end

  describe '#destroy' do
    let(:super_admin) { create(:super_admin) }

    it 'signs out the super admin and redirects to root path' do
      with_modified_env LOGRAGE_ENABLED: 'false' do
        sign_in(super_admin)
        delete :destroy
        expect(response).to redirect_to('/')
        expect(flash[:error]).to be_nil
      end
    end
  end
end
