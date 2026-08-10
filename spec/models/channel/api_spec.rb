# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::Api do
  # This validation happens in ApplicationRecord
  describe 'length validations' do
    let(:channel_api) { create(:channel_api) }

    context 'when it validates webhook_url length' do
      it 'valid when within limit' do
        channel_api.webhook_url = 'a' * Limits::URL_LENGTH_LIMIT
        expect(channel_api.valid?).to be true
      end

      it 'invalid when crossed the limit' do
        channel_api.webhook_url = 'a' * (Limits::URL_LENGTH_LIMIT + 1)
        channel_api.valid?
        expect(channel_api.errors[:webhook_url]).to include("is too long (maximum is #{Limits::URL_LENGTH_LIMIT} characters)")
      end
    end
  end

  describe '#additional_attributes=' do
    it 'merges into existing attributes instead of replacing them' do
      channel_api = create(:channel_api, additional_attributes: { 'import_placeholder' => true, 'source_provider' => 'zendesk' })

      channel_api.update!(additional_attributes: { 'include_private_notes' => 'true' })

      expect(channel_api.reload.additional_attributes).to eq(
        'import_placeholder' => true,
        'source_provider' => 'zendesk',
        'include_private_notes' => 'true'
      )
    end
  end
end
