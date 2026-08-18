require 'rails_helper'

RSpec.describe 'Public Portal Tickets', type: :request do
  let!(:account) { create(:account) }
  let!(:web_widget) { create(:channel_widget, account: account) }
  let!(:portal) do
    create(:portal, slug: 'test-portal', account: account, custom_domain: 'www.example.com', channel_web_widget: web_widget)
  end
  let(:inbox) { web_widget.inbox }
  let(:contact) { create(:contact, account: account, email: 'customer@example.com') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }
  let(:ticket) { create(:ticket, account: account, conversation: conversation, subject: 'Broken widget') }
  let(:token) { contact.signed_id(purpose: "portal_ticket_access_#{portal.id}", expires_in: 15.minutes) }

  before { account.enable_features!('tickets') }

  def sign_in_contact
    get "/hc/#{portal.slug}/tickets/verify", params: { token: token }
  end

  describe 'GET /hc/:slug/tickets/new' do
    it 'renders the submission form' do
      get "/hc/#{portal.slug}/tickets/new"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Submit a ticket')
    end

    context 'when the portal has no web widget' do
      before { portal.update!(channel_web_widget: nil) }

      it 'returns not found' do
        get "/hc/#{portal.slug}/tickets/new"

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the tickets feature is disabled' do
      before { account.disable_features!('tickets') }

      it 'returns not found' do
        get "/hc/#{portal.slug}/tickets/new"

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /hc/:slug/tickets' do
    let(:payload) do
      { name: 'Jane Doe', email: 'jane@example.com', subject: 'Cannot log in', ticket_type: 'issue', description: 'It keeps failing.' }
    end

    it 'creates a contact, a conversation and a ticket in the widget inbox' do
      expect { post "/hc/#{portal.slug}/tickets", params: payload }.to change(Ticket, :count).by(1)

      created_ticket = Ticket.last
      expect(created_ticket.subject).to eq('Cannot log in')
      expect(created_ticket.ticket_type).to eq('issue')
      expect(created_ticket.conversation.inbox_id).to eq(inbox.id)
      expect(created_ticket.conversation.contact.email).to eq('jane@example.com')
      expect(created_ticket.conversation.messages.last.content).to eq('It keeps failing.')
      expect(response.body).to include("##{created_ticket.conversation.display_id}")
    end

    it 'reuses an existing contact with the same email' do
      contact

      expect do
        post "/hc/#{portal.slug}/tickets", params: payload.merge(email: contact.email)
      end.not_to change(Contact, :count)

      expect(Ticket.last.conversation.contact_id).to eq(contact.id)
    end

    it 'rejects a submission without a subject' do
      expect { post "/hc/#{portal.slug}/tickets", params: payload.merge(subject: '') }.not_to change(Ticket, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Enter a subject.')
    end

    it 'rejects a submission with an invalid email' do
      expect { post "/hc/#{portal.slug}/tickets", params: payload.merge(email: 'not-an-email') }.not_to change(Ticket, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Enter a valid email address.')
    end

    context 'when the tickets feature is disabled' do
      before { account.disable_features!('tickets') }

      it 'returns not found' do
        expect { post "/hc/#{portal.slug}/tickets", params: payload }.not_to change(Ticket, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /hc/:slug/tickets/access' do
    it 'sends an access link when the email belongs to a contact' do
      contact

      expect do
        post "/hc/#{portal.slug}/tickets/access", params: { email: contact.email }
      end.to have_enqueued_mail(PortalTicketAccessMailer, :access_link)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Check your inbox')
    end

    it 'returns the same response without sending an email for an unknown address' do
      expect do
        post "/hc/#{portal.slug}/tickets/access", params: { email: 'nobody@example.com' }
      end.not_to have_enqueued_mail(PortalTicketAccessMailer, :access_link)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Check your inbox')
    end
  end

  describe 'GET /hc/:slug/tickets/verify' do
    it 'signs the contact in and redirects to the ticket list' do
      get "/hc/#{portal.slug}/tickets/verify", params: { token: token }

      expect(response).to redirect_to("/hc/#{portal.slug}/tickets")
    end

    it 'rejects a malformed token' do
      get "/hc/#{portal.slug}/tickets/verify", params: { token: 'nonsense' }

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include('This link has expired or is not valid.')
    end

    it 'rejects an expired token' do
      expired_token = contact.signed_id(purpose: "portal_ticket_access_#{portal.id}", expires_in: 15.minutes)

      travel_to(20.minutes.from_now) do
        get "/hc/#{portal.slug}/tickets/verify", params: { token: expired_token }
      end

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a token minted for another portal' do
      other_portal = create(:portal, slug: 'other-portal', account: account, channel_web_widget: web_widget)
      other_token = contact.signed_id(purpose: "portal_ticket_access_#{other_portal.id}", expires_in: 15.minutes)

      get "/hc/#{portal.slug}/tickets/verify", params: { token: other_token }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /hc/:slug/tickets' do
    it 'redirects to the access page without a session' do
      get "/hc/#{portal.slug}/tickets"

      expect(response).to redirect_to("/hc/#{portal.slug}/tickets/access")
    end

    it 'lists the tickets of the signed in contact' do
      ticket
      sign_in_contact

      get "/hc/#{portal.slug}/tickets"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Broken widget')
      expect(response.body).to include("##{conversation.display_id}")
    end

    it 'does not list tickets belonging to another contact' do
      other_conversation = create(:conversation, account: account, inbox: inbox)
      create(:ticket, account: account, conversation: other_conversation, subject: 'Somebody else problem')
      ticket
      sign_in_contact

      get "/hc/#{portal.slug}/tickets"

      expect(response.body).to include('Broken widget')
      expect(response.body).not_to include('Somebody else problem')
    end
  end

  describe 'GET /hc/:slug/tickets/:id' do
    it 'renders the ticket with its public messages' do
      create(:message, account: account, inbox: inbox, conversation: conversation, content: 'My widget is broken', message_type: :incoming)
      create(:message, account: account, inbox: inbox, conversation: conversation, content: 'Internal note', private: true)
      sign_in_contact

      get "/hc/#{portal.slug}/tickets/#{ticket.id}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('My widget is broken')
      expect(response.body).not_to include('Internal note')
    end

    it 'returns not found for a ticket belonging to another contact' do
      other_conversation = create(:conversation, account: account, inbox: inbox)
      other_ticket = create(:ticket, account: account, conversation: other_conversation)
      sign_in_contact

      get "/hc/#{portal.slug}/tickets/#{other_ticket.id}"

      expect(response).to have_http_status(:not_found)
    end

    it 'redirects to the access page without a session' do
      get "/hc/#{portal.slug}/tickets/#{ticket.id}"

      expect(response).to redirect_to("/hc/#{portal.slug}/tickets/access")
    end
  end
end
