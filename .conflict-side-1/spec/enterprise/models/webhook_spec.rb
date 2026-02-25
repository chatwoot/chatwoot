# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhook do
  let(:account) { create(:account) }
  let!(:webhook) { create(:webhook, account: account) }

  describe 'audit log' do
    context 'when webhook is created' do
      it 'has associated audit log created' do
        expect(Audited::Audit.where(auditable_type: 'Webhook', action: 'create').count).to eq 1
      end
    end

    context 'when webhook is updated' do
      it 'has associated audit log created' do
        webhook.update(url: 'https://example.com')
        expect(Audited::Audit.where(auditable_type: 'Webhook', action: 'update').count).to eq 1
      end
    end

    context 'when webhook is deleted' do
      it 'has associated audit log created' do
        webhook.destroy!
        expect(Audited::Audit.where(auditable_type: 'Webhook', action: 'destroy').count).to eq 1
      end
    end
  end
end
