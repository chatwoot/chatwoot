# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoClassificationListener do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:incoming_message) { create(:message, conversation: conversation, message_type: :incoming, content: 'Test message') }
  let(:outgoing_message) { create(:message, conversation: conversation, message_type: :outgoing, content: 'Agent reply') }
  let(:listener) { described_class.instance }

  before do
    create_list(:message, 2, conversation: conversation, message_type: :incoming, content: 'Previous messages')
  end

  describe '#message_created' do
    context 'when auto_label_enabled is true' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 3 })
      end

      it 'enqueues AutoClassificationJob' do
        event = Events::Base.new('message.created', Time.zone.now, { message: incoming_message })

        expect { listener.message_created(event) }
          .to have_enqueued_job(AutoClassificationJob)
          .with(conversation.id)
      end
    end

    context 'when auto_team_enabled is true' do
      before do
        account.update!(settings: { auto_team_enabled: true, auto_label_message_threshold: 3 })
      end

      it 'enqueues AutoClassificationJob' do
        event = Events::Base.new('message.created', Time.zone.now, { message: incoming_message })

        expect { listener.message_created(event) }
          .to have_enqueued_job(AutoClassificationJob)
          .with(conversation.id)
      end
    end

    context 'when both auto_label_enabled and auto_team_enabled are true' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_team_enabled: true, auto_label_message_threshold: 3 })
      end

      it 'enqueues AutoClassificationJob' do
        event = Events::Base.new('message.created', Time.zone.now, { message: incoming_message })

        expect { listener.message_created(event) }
          .to have_enqueued_job(AutoClassificationJob)
          .with(conversation.id)
      end
    end

    context 'when both features are disabled' do
      before do
        account.update!(settings: { auto_label_enabled: false, auto_team_enabled: false })
      end

      it 'does not enqueue job' do
        event = Events::Base.new('message.created', Time.zone.now, { message: incoming_message })

        expect { listener.message_created(event) }
          .not_to have_enqueued_job(AutoClassificationJob)
      end
    end

    context 'when auto settings are not set' do
      before do
        account.update!(settings: {})
      end

      it 'does not enqueue job' do
        event = Events::Base.new('message.created', Time.zone.now, { message: incoming_message })

        expect { listener.message_created(event) }
          .not_to have_enqueued_job(AutoClassificationJob)
      end
    end

    context 'when conversation already has label and team' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_team_enabled: true, auto_label_message_threshold: 3 })
        conversation.label_list.add('Existing Label')
        conversation.save!
        team = create(:team, account: account)
        conversation.update!(team: team)
      end

      it 'does not enqueue job' do
        event = Events::Base.new('message.created', Time.zone.now, { message: incoming_message })

        expect { listener.message_created(event) }
          .not_to have_enqueued_job(AutoClassificationJob)
      end
    end

    context 'when only label is assigned and auto_team is enabled' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_team_enabled: true, auto_label_message_threshold: 3 })
        conversation.label_list.add('Existing Label')
        conversation.save!
      end

      it 'enqueues job for team assignment' do
        event = Events::Base.new('message.created', Time.zone.now, { message: incoming_message })

        expect { listener.message_created(event) }
          .to have_enqueued_job(AutoClassificationJob)
          .with(conversation.id)
      end
    end

    context 'when only team is assigned and auto_label is enabled' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_team_enabled: true, auto_label_message_threshold: 3 })
        team = create(:team, account: account)
        conversation.update!(team: team)
      end

      it 'enqueues job for label assignment' do
        event = Events::Base.new('message.created', Time.zone.now, { message: incoming_message })

        expect { listener.message_created(event) }
          .to have_enqueued_job(AutoClassificationJob)
          .with(conversation.id)
      end
    end

    context 'when message threshold is not met' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 5 })
        conversation.messages.destroy_all
        create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Message')
      end

      it 'does not enqueue job' do
        event = Events::Base.new('message.created', Time.zone.now, { message: incoming_message })

        expect { listener.message_created(event) }
          .not_to have_enqueued_job(AutoClassificationJob)
      end
    end

    context 'when message threshold is exactly met' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 3 })
        conversation.messages.destroy_all
        create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Message')
      end

      it 'enqueues job' do
        expect { listener.message_created(Events::Base.new('message.created', Time.zone.now, { message: incoming_message })) }
          .to have_enqueued_job(AutoClassificationJob)
      end
    end

    context 'when message threshold is exceeded' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 3 })
        conversation.messages.destroy_all
        create_list(:message, 5, conversation: conversation, message_type: :incoming, content: 'Message')
      end

      it 'enqueues job' do
        expect { listener.message_created(Events::Base.new('message.created', Time.zone.now, { message: incoming_message })) }
          .to have_enqueued_job(AutoClassificationJob)
      end
    end

    context 'when threshold is not configured' do
      before do
        account.update!(settings: { auto_label_enabled: true })
        conversation.messages.destroy_all
        create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Message')
      end

      it 'uses default threshold of 3' do
        expect { listener.message_created(Events::Base.new('message.created', Time.zone.now, { message: incoming_message })) }
          .to have_enqueued_job(AutoClassificationJob)
      end
    end

    context 'with custom threshold' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 7 })
        conversation.messages.destroy_all
        create_list(:message, 7, conversation: conversation, message_type: :incoming, content: 'Message')
      end

      it 'respects custom threshold' do
        expect { listener.message_created(Events::Base.new('message.created', Time.zone.now, { message: incoming_message })) }
          .to have_enqueued_job(AutoClassificationJob)
      end
    end

    context 'with mixed incoming and outgoing messages' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 3 })
        conversation.messages.destroy_all
        create(:message, conversation: conversation, message_type: :incoming, content: 'Message 1')
        create(:message, conversation: conversation, message_type: :outgoing, content: 'Reply 1')
        create(:message, conversation: conversation, message_type: :incoming, content: 'Message 2')
        create(:message, conversation: conversation, message_type: :incoming, content: 'Message 3')
      end

      it 'counts only incoming messages' do
        expect { listener.message_created(Events::Base.new('message.created', Time.zone.now, { message: incoming_message })) }
          .to have_enqueued_job(AutoClassificationJob)
      end
    end

    context 'when message is outgoing' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 3 })
      end

      it 'does not enqueue job' do
        event = Events::Base.new('message.created', Time.zone.now, { message: outgoing_message })

        expect { listener.message_created(event) }
          .not_to have_enqueued_job(AutoClassificationJob)
      end
    end
  end
end
