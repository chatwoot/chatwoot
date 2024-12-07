# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversations::EventDataPresenter do
  let!(:presenter) { described_class.new(conversation) }
  let!(:conversation) { create(:conversation) }
  let!(:applied_sla) { create(:applied_sla, conversation: conversation) }
  let!(:sla_event) { create(:sla_event, conversation: conversation, applied_sla: applied_sla) }

  describe '#push_data' do
    it 'returns push event payload with applied sla & sla events if the feature is enabled' do
      conversation.account.enable_features!('sla')

      expect(presenter.push_data).to include(
        {
          applied_sla: applied_sla.push_event_data,
          sla_events: [sla_event.push_event_data]
        }
      )
    end

    it 'returns push event payload without applied sla & sla events if the feature is disabled' do
      conversation.account.disable_features!('sla')

      expect(presenter.push_data).not_to include(:applied_sla, :sla_events)
    end
  end
end
