# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CampaignContact do
  describe 'associations' do
    it { is_expected.to belong_to(:campaign) }
    it { is_expected.to belong_to(:contact) }
  end

  describe 'validations' do
    subject { create(:campaign_contact) }

    it { is_expected.to validate_uniqueness_of(:campaign_id).scoped_to(:contact_id) }
  end

  describe 'enums' do
    it {
      expect(subject).to define_enum_for(:status)
        .with_values(pending: 0, sent: 1, failed: 2, skipped: 3)
        .backed_by_column_of_type(:integer)
    }
  end

  describe 'scopes' do
    let(:campaign) { create(:campaign) }
    let!(:sent_contact) { create(:campaign_contact, campaign: campaign, status: :sent) }
    let!(:failed_contact) { create(:campaign_contact, campaign: campaign, status: :failed) }
    let!(:pending_contact) { create(:campaign_contact, campaign: campaign, status: :pending) }
    let!(:skipped_contact) { create(:campaign_contact, campaign: campaign, status: :skipped) }

    describe '.sent_successfully' do
      it 'returns only sent contacts' do
        expect(described_class.sent_successfully).to contain_exactly(sent_contact)
      end
    end

    describe '.with_errors' do
      it 'returns only failed contacts' do
        expect(described_class.with_errors).to contain_exactly(failed_contact)
      end
    end

    describe '.not_sent' do
      it 'returns pending and skipped contacts' do
        expect(described_class.not_sent).to contain_exactly(pending_contact, skipped_contact)
      end
    end
  end

  describe '#mark_as_sent!' do
    let(:campaign_contact) { create(:campaign_contact, status: :pending) }

    it 'updates status to sent' do
      expect { campaign_contact.mark_as_sent! }
        .to change(campaign_contact, :status).from('pending').to('sent')
    end

    it 'sets sent_at timestamp' do
      expect { campaign_contact.mark_as_sent! }
        .to change(campaign_contact, :sent_at).from(nil)
    end
  end

  describe '#mark_as_failed!' do
    let(:campaign_contact) { create(:campaign_contact, status: :pending) }
    let(:error_message) { 'Template not found' }

    it 'updates status to failed' do
      expect { campaign_contact.mark_as_failed!(error_message) }
        .to change(campaign_contact, :status).from('pending').to('failed')
    end

    it 'sets error_message' do
      expect { campaign_contact.mark_as_failed!(error_message) }
        .to change(campaign_contact, :error_message).from(nil).to(error_message)
    end

    it 'sets sent_at timestamp' do
      expect { campaign_contact.mark_as_failed!(error_message) }
        .to change(campaign_contact, :sent_at).from(nil)
    end
  end

  describe '#mark_as_skipped!' do
    let(:campaign_contact) { create(:campaign_contact, status: :pending) }
    let(:reason) { 'No phone number' }

    it 'updates status to skipped' do
      expect { campaign_contact.mark_as_skipped!(reason) }
        .to change(campaign_contact, :status).from('pending').to('skipped')
    end

    it 'sets error_message with reason' do
      expect { campaign_contact.mark_as_skipped!(reason) }
        .to change(campaign_contact, :error_message).from(nil).to(reason)
    end
  end
end
