require 'rails_helper'

RSpec.describe ScheduledMessages::SendScheduledMessageJob, type: :job do
  let(:account) { create(:account) }
  let(:author) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:scheduled_message) { create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: author) }

  describe '#perform' do
    it 'creates message with metadata and marks as sent' do
      travel_to(3.minutes.from_now) do
        described_class.new.perform(scheduled_message.id)

        message = conversation.messages.last
        expect(message.content).to eq(scheduled_message.content)
        expect(message.additional_attributes['scheduled_message_id']).to eq(scheduled_message.id)
        expect(message.additional_attributes['scheduled_by']).to include('id' => author.id, 'type' => 'User')
        expect(scheduled_message.reload.status).to eq('sent')
      end
    end

    it 'sets automation_rule_id when author is AutomationRule' do
      automation_rule = create(:automation_rule, account: account)
      scheduled_message = create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: automation_rule)

      travel_to(3.minutes.from_now) do
        described_class.new.perform(scheduled_message.id)

        message = conversation.messages.last
        expect(message.content_attributes['automation_rule_id']).to eq(automation_rule.id)
        expect(message.additional_attributes['scheduled_by']).to include('id' => automation_rule.id, 'type' => 'AutomationRule')
      end
    end

    it 'includes template_params when present' do
      template_params = { 'name' => 'sample_template', 'language' => 'en' }
      scheduled_message = create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: author, content: nil,
                                                     template_params: template_params)

      travel_to(3.minutes.from_now) do
        described_class.new.perform(scheduled_message.id)

        expect(conversation.messages.last.additional_attributes['template_params']).to eq(template_params)
      end
    end

    it 'includes attachment when present' do
      file = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
      scheduled_message = create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: author, content: nil,
                                                     attachment: file)

      travel_to(3.minutes.from_now) do
        described_class.new.perform(scheduled_message.id)

        expect(conversation.messages.last.attachments.count).to eq(1)
      end
    end

    it 'marks as failed on error' do
      allow(Messages::MessageBuilder).to receive(:new).and_raise(StandardError, 'boom')

      travel_to(3.minutes.from_now) do
        described_class.new.perform(scheduled_message.id)

        expect(scheduled_message.reload.status).to eq('failed')
      end
    end

    it 'skips when not pending' do
      draft = create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: author, status: :draft,
                                         scheduled_at: nil)

      travel_to(3.minutes.from_now) do
        expect { described_class.new.perform(draft.id) }.not_to(change { conversation.messages.count })
      end
    end

    it 'skips when not due' do
      future = create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: author,
                                          scheduled_at: 10.minutes.from_now)

      travel_to(3.minutes.from_now) do
        expect { described_class.new.perform(future.id) }.not_to(change { conversation.messages.count })
      end
    end
  end
end
