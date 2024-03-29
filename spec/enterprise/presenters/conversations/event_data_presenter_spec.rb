# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversations::EventDataPresenter do
  let(:presenter) { described_class.new(conversation) }
  let(:conversation) { create(:conversation) }

  describe '#push_data' do
    it 'returns push event payload with applied sla & sla events' do
      applied_sla = create(:applied_sla, conversation: conversation)
      sla_event = create(:sla_event, conversation: conversation, applied_sla: applied_sla)
      conversation.reload

      expect(presenter.push_data).to include(
        {
          applied_sla: applied_sla.push_event_data,
          sla_events: [sla_event.push_event_data]
        }
      )
    end
  end
end
