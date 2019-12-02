require 'rails_helper'

describe '/widget', type: :request do
  let(:channel_widget) { create(:channel_widget) }

  describe 'GET /widget' do
    it 'renders the page correctly when called with website_token' do
      get widget_url(website_token: channel_widget.website_token)
      expect(response).to be_successful
    end

    it 'raises when called with website_token' do
      expect { get widget_url }.to raise_exception ActiveRecord::RecordNotFound
    end
  end

  describe 'POST /widget/update_contact' do
    let(:channel_widget) { create(:channel_widget) }
    let(:contact) { create(:contact, account: channel_widget.account) }
    let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: channel_widget.inbox) }

    it 'updates the contact with posted params' do
      post update_contact_widget_url(contact: { email: 'test@test.com', name: 'test' },
                                     source_id: contact_inbox.source_id, website_token: channel_widget.website_token)
      contact.reload
      expect(contact.email).to eql 'test@test.com'
    end
  end
end
