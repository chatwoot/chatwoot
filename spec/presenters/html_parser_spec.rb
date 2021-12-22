require 'rails_helper'
RSpec.describe HtmlParser do
  include ActionMailbox::TestHelper

  describe 'parsed mail decorator' do
    let(:html_mail) { create_inbound_email_from_fixture('welcome_html.eml').mail }

    it 'parse html content in the mail' do
      decorated_html_mail = described_class.parse_reply(html_mail.text_part.decoded)
      expect(decorated_html_mail[0..70]).to eq(
        "I'm learning English as a first language for the past 13 years, but to "
      )
    end
  end
end
