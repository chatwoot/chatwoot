require 'rails_helper'

describe Digitaltolk::SendEmailTicketService do
  let(:service) { described_class.new(account, user, params, for_issue: false) }
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:second_user) { create(:user, account: account) }
  let(:booking_id) { '3359288' }
  let(:email) { user.email }
  let(:creator) { create(:user, account: account) }
  let(:team) { create(:team) }

  describe '#perform' do
    let(:status) { 'open' }
    let(:customer_id) { '123' }
    let(:params) do
      {
        body: 'Reply with message_type',
        requester: {
          name: user.name,
          email: email
        },
        booking_id: booking_id,
        title: 'Subject',
        status: status,
        tags: 'emails from DT',
        created_by: {
          email: creator.name,
          name: creator.email
        },
        customer_id: customer_id,
        inbox_id: inbox.id,
        recipient_type: 2,
        team_id: team.id
      }
    end

    it 'creates a conversation and message' do
      result = service.perform
      expect(result[:success]).to be_truthy
      expect(result[:message]).to eq('Email sent!')
      expect(result[:conversation_id]).not_to be_nil
      convo = inbox.conversations.find_by(display_id: result[:conversation_id])
      expect(convo.team).to eq(team)
    end

    context 'with uniqueness of conversation' do
      it 'send multiple message, same email, booking_id' do
        result = service.perform
        result2 = service.perform
        expect(result[:conversation_id]).to eq(result2[:conversation_id])
      end

      context 'with different email' do
        it do
          result = service.perform
          requester = {
            name: second_user.name,
            email: second_user.email
          }
          result2 = described_class.new(account, user, params.merge({ requester: requester }), for_issue: false).perform
          expect(result[:conversation_id]).not_to eq(result2[:conversation_id])
        end
      end

      context 'with different booking_id' do
        it do
          result = service.perform
          result2 = described_class.new(account, user, params.merge({ booking_id: 'A13456A' }), for_issue: false).perform
          expect(result[:conversation_id]).not_to eq(result2[:conversation_id])
        end
      end
    end

    context 'with conversation status' do
      let(:status) { 'resolved' }

      it 'updates status correctly' do
        result = service.perform
        convo = inbox.conversations.find_by(display_id: result[:conversation_id])
        expect(convo.status).to eq('resolved')
      end

      context 'with errors when invalid' do
        let(:status) { 'solved' }

        it do
          result = service.perform
          expect(result[:success]).to be_truthy
          expect(result[:message]).to eq('Email sent!')
          convo = inbox.conversations.find_by(display_id: result[:conversation_id])
          expect(convo.status).to eq('open')
        end
      end
    end

    context 'with customer id' do
      it 'creates a conversation with customer id' do
        result = service.perform
        convo = inbox.conversations.find_by(display_id: result[:conversation_id])
        expect(convo.contact.custom_attributes['customer_id']).to eq('123')
      end
    end

    context 'without customer_id' do
      let(:customer_id) { nil }

      it 'does not create a conversation with customer id' do
        result = service.perform
        convo = inbox.conversations.find_by(display_id: result[:conversation_id])
        expect(convo.contact.custom_attributes['customer_id']).to be_nil
      end

      it 'does not update existing contact customer id' do
        contact = create(:contact, email: email, custom_attributes: { customer_id: '321' })
        create(:conversation, contact: contact, inbox: inbox, custom_attributes: { booking_id: booking_id })

        result = service.perform
        convo = inbox.conversations.find_by(display_id: result[:conversation_id])
        expect(contact).to eq(convo.contact)
        expect(convo.contact.custom_attributes['customer_id']).to eq('321')
      end
    end

    context 'with user signature' do
      let(:user) { create(:user, account: account, message_signature: 'message signature test') }

      it 'creates a message with signature' do
        result = service.perform
        convo = inbox.conversations.find_by(display_id: result[:conversation_id])
        expect(convo.messages.last.content).to include('message signature test')
      end
    end
  end
end
