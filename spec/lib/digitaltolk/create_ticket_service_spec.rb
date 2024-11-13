require 'rails_helper'
describe Digitaltolk::CreateTicketService do
  subject { described_class.new(account, params) }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:base_params) do
    {
      contact_kind: 3,
      email: 'test@test.com',
      issue_type: 'Question',
      name: Faker::Name.name,
      inbox_id: inbox.id,
      note: 'Hello',
      phone: '9100062123',
      phoneCode: '+63',
      labels: ['label1'],
      custom_attributes: {
        issue_type: 'Question',
        contact_type: 'Översättare'
      },
      subject: 'test',
      cc_emails: 'test1@test.com, test2@test.com',
      bcc_emails: 'test3@test.com, test4@test.com',
      private: private_note,
      status: 'open'
    }
  end

  describe '#perform' do
    let(:params) { ActionController::Parameters.new(base_params) }

    context 'with private note true' do
      let(:private_note) { true }

      it { expect { subject.perform }.to change(Conversation, :count).by(1) }
      it { expect { subject.perform }.to change(Message.where(private: true), :count).by(1) }
    end

    context 'with private note false' do
      let(:private_note) { false }

      it { expect { subject.perform }.to change(Conversation, :count).by(1) }
      it { expect { subject.perform }.to change(Message.where(private: false).outgoing, :count).by(1) }

      it 'creates a message with the correct content' do
        subject.perform
        expect(subject.conversation.messages.outgoing.last.content).to eq('Hello')
      end

      it 'adds the correct labels' do
        subject.perform

        expect(subject.conversation.cached_label_list).to include('label1')
        expect(subject.conversation.cached_label_list).to include('översättare_contact')
        expect(subject.conversation.cached_label_list).to include('question')
        expect(subject.conversation.cached_label_list).to include('created-by-agent')
      end
    end

    context 'with true private note as string' do
      let(:private_note) { 'true' }

      it { expect { subject.perform }.to change(Message.where(private: true), :count).by(1) }
    end

    context 'with invalid phone' do
      let(:private_note) { false }
      let(:params) { ActionController::Parameters.new(base_params.merge(phone: '+639 (123) 12341')) }

      it 'raises ActiveRecord::RecordInvalid' do
        expect { subject.perform }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with issue type' do
      let(:private_note) { false }

      context 'with question' do
        let(:params) { ActionController::Parameters.new(base_params.merge(issue_type: 'Question')) }

        it 'adds the correct labels' do
          subject.perform

          expect(subject.conversation.cached_label_list).to include('question')
        end
      end

      context 'with feedback' do
        let(:params) { ActionController::Parameters.new(base_params.merge(issue_type: 'Feedback')) }

        it 'adds the correct labels' do
          subject.perform

          expect(subject.conversation.cached_label_list).to include('feedback')
        end
      end

      context 'with 2nd-line-support' do
        let(:params) { ActionController::Parameters.new(base_params.merge(issue_type: '2nd Line Support')) }

        it 'adds the correct labels' do
          subject.perform

          expect(subject.conversation.cached_label_list).to include('2nd-line-support')
        end
      end
    end

    context 'when saving' do
      let(:inbox) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
      let(:private_note) { false }
      let(:params) { ActionController::Parameters.new(base_params) }

      it 'add correct custom attributes' do
        subject.perform

        expect(subject.conversation.custom_attributes).to eq('issue_type' => 'Question', 'contact_type' => 'Översättare')
      end

      it 'creates a conversation with the correct attributes' do
        subject.perform

        expect(subject.conversation.contact.email).to eq('test@test.com')
        expect(subject.conversation.contact.phone_number).to eq('+639100062123')
        expect(subject.conversation.contact.name).to eq(base_params[:name])

        message = subject.conversation.messages.outgoing.last
        expect(message.content_attributes[:cc_emails]).to eq ['test1@test.com', 'test2@test.com']
        expect(message.content_attributes[:bcc_emails]).to eq ['test3@test.com', 'test4@test.com']
      end
    end

    context 'with status' do
      let(:private_note) { false }

      context 'with open status' do
        let(:params) { ActionController::Parameters.new(base_params.merge(status: 'open')) }

        it 'creates a conversation with the correct status' do
          subject.perform

          expect(subject.conversation.status).to eq('open')
        end
      end

      context 'with resolved status' do
        let(:params) { ActionController::Parameters.new(base_params.merge(status: 'resolved')) }

        it 'creates a conversation with the correct status' do
          subject.perform

          expect(subject.conversation.status).to eq('resolved')
        end
      end

      context 'with pending status' do
        let(:params) { ActionController::Parameters.new(base_params.merge(status: 'pending')) }

        it 'creates a conversation with the correct status' do
          subject.perform

          expect(subject.conversation.status).to eq('pending')
        end
      end
    end
  end
end
