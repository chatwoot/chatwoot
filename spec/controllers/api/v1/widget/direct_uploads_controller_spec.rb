require 'rails_helper'

RSpec.describe '/api/v1/widget/direct_uploads', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }

  describe 'POST /api/v1/widget/direct_uploads' do
    context 'when post request is made' do
      around do |example|
        original = ActionController::Base.allow_forgery_protection
        ActionController::Base.allow_forgery_protection = true
        example.run
      ensure
        ActionController::Base.allow_forgery_protection = original
      end

      before do
        token
        contact
        payload
      end

      it 'creates a blob with a valid widget token and no CSRF token' do
        post api_v1_widget_direct_uploads_url,
             params: {
               website_token: web_widget.website_token,
               blob: {
                 filename: 'avatar.png',
                 byte_size: '1234',
                 checksum: 'dsjbsdhbfif3874823mnsdbf',
                 content_type: 'image/png'
               }
             },
             headers: { 'X-Auth-Token' => token }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['content_type']).to eq('image/png')
      end
    end
  end
end
