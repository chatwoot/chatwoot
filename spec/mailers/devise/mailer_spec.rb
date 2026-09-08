require 'rails_helper'

RSpec.describe Devise::Mailer do
  it 'carries the requested redirect in the password edit link' do
    user = create(:user)
    redirect_url = 'settings/billing?plan_handle=growth&shop=store.myshopify.com'
    mail = described_class
           .with(redirect_url: redirect_url)
           .reset_password_instructions(user, 'reset-token')

    expect(CGI.unescapeHTML(mail.body.to_s)).to include(
      'route_url=settings%2Fbilling%3Fplan_handle%3Dgrowth%26shop%3Dstore.myshopify.com'
    )
  end
end
