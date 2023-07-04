require 'rails_helper'

describe CustomViewsListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:filter) do
    create(:custom_filter, account: account, query:
    {
      payload: [{
        values: [:open, :resolved], attribute_key: 'status',
        query_operator: nil, attribute_model: 'standard',
        filter_operator: 'equal_to', custom_attribute_type: ''
      }]
    })
  end
  let(:conversation) { create(:conversation, account: account) }
  let(:condition_match) { double }
  let(:action_service) { double }

  before do
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
  end

  describe 'conversation_created' do
    let(:event) do
      Events::Base.new('conversation_created', Time.zone.now, { conversation: conversation,
                                                                changed_attributes: {} })
    end

    context 'when filter_records is non zero' do
      it 'update redis count' do
        listener.conversation_created(event)
        expect(filter.fetch_record_count_from_redis).to eq(1)
      end

      it 'dispatches action broadcast for custom_filter update' do
        listener.conversation_created(event)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(CustomFilter::CUSTOM_FILTER_UPDATED, kind_of(Time), { custom_filter: filter })
      end
    end
  end

  describe 'conversation_updated' do
    let(:event) do
      Events::Base.new('conversation_updated', Time.zone.now, { conversation: conversation,
                                                                changed_attributes: {} })
    end

    context 'when filter_records is non zero' do
      it 'update redis count' do
        listener.conversation_updated(event)
        expect(filter.fetch_record_count_from_redis).to eq(1)
      end

      it 'dispatches action broadcast for custom_filter update' do
        listener.conversation_updated(event)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(CustomFilter::CUSTOM_FILTER_UPDATED, kind_of(Time), { custom_filter: filter })
      end
    end
  end
end
