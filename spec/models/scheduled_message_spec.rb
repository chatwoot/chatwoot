require 'rails_helper'

RSpec.describe ScheduledMessage, type: :model do
  let(:account) { create(:account) }
  let(:author) { create(:user, account: account) }
  let(:automation_rule) { create(:automation_rule, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

  def build_scheduled_message(attrs = {})
    ScheduledMessage.new({
      account: account,
      inbox: inbox,
      conversation: conversation,
      author: author,
      content: 'Hello',
      status: :pending,
      scheduled_at: 1.hour.from_now
    }.merge(attrs))
  end

  def create_scheduled_message(attrs = {})
    build_scheduled_message(attrs).tap(&:save!)
  end

  describe 'validations' do
    describe 'content' do
      it 'requires content when no template params or attachment' do
        scheduled_message = build_scheduled_message(content: nil, template_params: {})

        expect(scheduled_message).not_to be_valid
        expect(scheduled_message.errors[:content]).to be_present
      end

      it 'allows template params without content' do
        scheduled_message = build_scheduled_message(content: nil, template_params: { id: '123456789', name: 'test_template' })

        expect(scheduled_message).to be_valid
      end

      it 'allows attachment without content' do
        scheduled_message = build_scheduled_message(content: nil, template_params: {})
        scheduled_message.attachment.attach(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )

        expect(scheduled_message).to be_valid
      end
    end

    describe 'author' do
      it 'accepts automation rules as author' do
        scheduled_message = build_scheduled_message(author: automation_rule)

        expect(scheduled_message).to be_valid
      end
    end

    describe 'status on create' do
      it 'allows creating with draft status' do
        scheduled_message = build_scheduled_message(status: :draft, scheduled_at: nil)

        expect(scheduled_message).to be_valid
      end

      it 'allows creating with pending status' do
        scheduled_message = build_scheduled_message

        expect(scheduled_message).to be_valid
      end

      it 'does not allow creating with sent status' do
        scheduled_message = build_scheduled_message(status: :sent)

        expect(scheduled_message).not_to be_valid
        expect(scheduled_message.errors[:status]).to be_present
      end

      it 'does not allow creating with failed status' do
        scheduled_message = build_scheduled_message(status: :failed)

        expect(scheduled_message).not_to be_valid
        expect(scheduled_message.errors[:status]).to be_present
      end
    end

    describe 'scheduled_at' do
      it 'requires scheduled_at when status is pending' do
        scheduled_message = build_scheduled_message(status: :pending, scheduled_at: nil)

        expect(scheduled_message).not_to be_valid
        expect(scheduled_message.errors[:scheduled_at]).to be_present
      end

      it 'does not require scheduled_at when status is draft' do
        scheduled_message = build_scheduled_message(status: :draft, scheduled_at: nil)

        expect(scheduled_message).to be_valid
      end

      it 'requires scheduled_at to be in the future when pending' do
        scheduled_message = build_scheduled_message(status: :pending, scheduled_at: 1.minute.ago)

        expect(scheduled_message).not_to be_valid
        expect(scheduled_message.errors[:scheduled_at]).to include('must be in the future')
      end

      it 'validates future scheduled_at when changing status to pending' do
        scheduled_message = create_scheduled_message(status: :draft, scheduled_at: nil)
        scheduled_message.status = :pending
        scheduled_message.scheduled_at = 1.minute.ago

        expect(scheduled_message).not_to be_valid
        expect(scheduled_message.errors[:scheduled_at]).to include('must be in the future')
      end
    end

    describe 'editability' do
      it 'allows editing draft messages' do
        scheduled_message = create_scheduled_message(status: :draft, scheduled_at: nil)
        scheduled_message.content = 'Updated content'

        expect(scheduled_message).to be_valid
      end

      it 'allows editing pending messages' do
        scheduled_message = create_scheduled_message
        scheduled_message.content = 'Updated content'

        expect(scheduled_message).to be_valid
      end

      it 'does not allow editing content of sent messages' do
        scheduled_message = create_scheduled_message
        scheduled_message.update!(status: :sent)

        expect { scheduled_message.update!(content: 'Updated content') }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors[:base]).to include('Scheduled message can only be modified while draft or pending')
        end
      end

      it 'does not allow editing content of failed messages' do
        scheduled_message = create_scheduled_message
        scheduled_message.update!(status: :failed)

        expect { scheduled_message.update!(content: 'Updated content') }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors[:base]).to include('Scheduled message can only be modified while draft or pending')
        end
      end

      it 'allows changing status from sent to failed' do
        scheduled_message = create_scheduled_message
        scheduled_message.update!(status: :sent)

        expect { scheduled_message.update!(status: :failed) }.not_to raise_error
        expect(scheduled_message.reload.status).to eq('failed')
      end

      it 'allows changing status from failed to sent' do
        scheduled_message = create_scheduled_message
        scheduled_message.update!(status: :failed)

        expect { scheduled_message.update!(status: :sent) }.not_to raise_error
        expect(scheduled_message.reload.status).to eq('sent')
      end
    end

    describe 'destroy' do
      it 'allows deleting draft messages' do
        scheduled_message = create_scheduled_message(status: :draft, scheduled_at: nil)

        expect { scheduled_message.destroy }.to change(described_class, :count).by(-1)
      end

      it 'allows deleting pending messages' do
        scheduled_message = create_scheduled_message

        expect { scheduled_message.destroy }.to change(described_class, :count).by(-1)
      end

      it 'allows deleting pending messages with attachments' do
        scheduled_message = create_scheduled_message
        scheduled_message.attachment.attach(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )

        expect { scheduled_message.destroy! }.to change(described_class, :count).by(-1)
      end

      it 'allows destroying conversation with pending scheduled messages with attachments' do
        scheduled_message = create_scheduled_message
        scheduled_message.attachment.attach(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )

        expect { conversation.destroy! }.to change(described_class, :count).by(-1)
      end

      it 'allows destroying conversation with sent scheduled messages with attachments' do
        scheduled_message = create_scheduled_message
        scheduled_message.attachment.attach(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )
        scheduled_message.update!(status: :sent)

        expect { conversation.destroy! }.to change(described_class, :count).by(-1)
      end

      it 'allows deleting sent messages at model level (controller enforces restriction)' do
        scheduled_message = create_scheduled_message
        scheduled_message.update!(status: :sent)

        expect { scheduled_message.destroy! }.to change(described_class, :count).by(-1)
      end

      it 'allows deleting failed messages at model level (controller enforces restriction)' do
        scheduled_message = create_scheduled_message
        scheduled_message.update!(status: :failed)

        expect { scheduled_message.destroy! }.to change(described_class, :count).by(-1)
      end
    end
  end

  describe '.due_for_sending' do
    it 'returns only pending messages scheduled up to the current minute' do
      freeze_time

      due_same_minute = create_scheduled_message(
        scheduled_at: 1.minute.from_now
      )
      overdue = create_scheduled_message(
        scheduled_at: 2.minutes.from_now
      )
      create_scheduled_message(
        content: 'Future message',
        scheduled_at: 10.minutes.from_now
      )
      create_scheduled_message(
        scheduled_at: 1.minute.from_now,
        status: :draft
      )

      sent_message = create_scheduled_message(
        scheduled_at: 1.minute.from_now
      )
      sent_message.update!(status: :sent)

      failed_message = create_scheduled_message(
        scheduled_at: 1.minute.from_now
      )
      failed_message.update!(status: :failed)

      # NOTE: Travel to a time where due_same_minute and overdue are due but not_due_yet is not
      travel_to(5.minutes.from_now)

      expect(described_class.due_for_sending.pluck(:id)).to contain_exactly(due_same_minute.id, overdue.id)
    end
  end

  describe '#process_message_variables' do
    it 'renders Liquid variables with contact data on save' do
      contact.update!(name: 'John Doe')
      scheduled_message = build_scheduled_message(content: 'Hello {{contact.name}}!')

      scheduled_message.save!

      expect(scheduled_message.content).to eq('Hello John Doe!')
    end

    it 'renders conversation variables on save' do
      scheduled_message = build_scheduled_message(content: 'Conversation #{{conversation.display_id}}')

      scheduled_message.save!

      expect(scheduled_message.content).to eq("Conversation ##{conversation.display_id}")
    end

    it 'preserves original content when Liquid syntax is invalid' do
      original_content = 'Hello {{contact.name | }'
      scheduled_message = build_scheduled_message(content: original_content)

      scheduled_message.save!

      expect(scheduled_message.content).to eq(original_content)
    end

    it 'does not process variables when content has not changed' do
      contact.update!(name: 'John Doe')
      scheduled_message = create_scheduled_message(content: 'Hello {{contact.name}}!')

      expect(scheduled_message.content).to eq('Hello John Doe!')

      # Update a different field
      scheduled_message.update!(scheduled_at: 2.hours.from_now)

      # Content should remain the same
      expect(scheduled_message.content).to eq('Hello John Doe!')
    end

    it 'preserves Liquid variables inside inline code blocks' do
      scheduled_message = build_scheduled_message(content: 'Use `{{contact.name}}` to get the name')

      scheduled_message.save!

      expect(scheduled_message.content).to eq('Use `{{contact.name}}` to get the name')
    end
  end
end
