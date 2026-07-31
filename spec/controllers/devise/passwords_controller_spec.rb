require 'rails_helper'

RSpec.describe 'Passwords Controller', type: :request do
  it 'forwards the requested redirect to password recovery' do
    user = create(:user)
    redirect_url = 'settings/billing?plan_handle=growth&shop=store.myshopify.com'
    allow(User).to receive(:from_email).with(user.email).and_return(user)
    allow(user).to receive(:send_reset_password_instructions)

    post user_password_path, params: { email: user.email, redirect_url: redirect_url }, as: :json

    expect(user).to have_received(:send_reset_password_instructions).with(redirect_url: redirect_url)
    expect(response).to have_http_status(:ok)
  end
end
