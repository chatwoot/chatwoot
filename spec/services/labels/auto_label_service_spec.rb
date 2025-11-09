# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::AutoLabelService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:service) { described_class.new(conversation: conversation) }
  let!(:label1) { create(:label, title: 'billing', account: account) }
  let!(:label2) { create(:label, title: 'support', account: account) }

  describe '#perform' do
    context 'when auto-labeling is enabled' do
      before do
        account.update!(settings: { auto_label_enabled: true })
      end

      context 'when conversation has no labels' do
        it 'applies suggested label to conversation' do
          classifier_service = instance_double(Labels::OpenaiClassifierService)
          allow(Labels::OpenaiClassifierService).to receive(:new)
            .with(conversation)
            .and_return(classifier_service)
          allow(classifier_service).to receive(:suggest_labels)
            .and_return({ label_id: label1.id })

          expect(conversation).to receive(:add_labels).with([label1.title])

          service.perform
        end

        it 'logs successful auto-labeling' do
          classifier_service = instance_double(Labels::OpenaiClassifierService)
          allow(Labels::OpenaiClassifierService).to receive(:new).and_return(classifier_service)
          allow(classifier_service).to receive(:suggest_labels)
            .and_return({ label_id: label1.id })
          allow(conversation).to receive(:add_labels)

          expect(Rails.logger).to receive(:info)
            .with("Auto-labeled conversation #{conversation.id} with: #{label1.title}")

          service.perform
        end
      end

      context 'when conversation already has labels' do
        before do
          conversation.label_list.add('Existing Label')
          conversation.save!
        end

        it 'does not apply new labels' do
          instance_double(Labels::OpenaiClassifierService)
          expect(Labels::OpenaiClassifierService).not_to receive(:new)
          expect(conversation).not_to receive(:add_labels)

          service.perform
        end
      end

      context 'when classifier returns nil label_id' do
        it 'does not apply any labels' do
          classifier_service = instance_double(Labels::OpenaiClassifierService)
          allow(Labels::OpenaiClassifierService).to receive(:new).and_return(classifier_service)
          allow(classifier_service).to receive(:suggest_labels).and_return({ label_id: nil })

          expect(conversation).not_to receive(:add_labels)

          service.perform
        end
      end
    end

    context 'when auto-labeling is disabled' do
      before do
        account.update!(settings: { auto_label_enabled: false })
      end

      it 'does not process the conversation' do
        expect(Labels::OpenaiClassifierService).not_to receive(:new)

        service.perform
      end
    end

    context 'when account settings are empty' do
      before do
        account.update!(settings: {})
      end

      it 'does not process the conversation' do
        expect(Labels::OpenaiClassifierService).not_to receive(:new)

        service.perform
      end
    end

    context 'when an error occurs' do
      before do
        account.update!(settings: { auto_label_enabled: true })
      end

      it 'logs the error and re-raises for job retry' do
        classifier_service = instance_double(Labels::OpenaiClassifierService)
        allow(Labels::OpenaiClassifierService).to receive(:new).and_return(classifier_service)
        allow(classifier_service).to receive(:suggest_labels)
          .and_raise(StandardError.new('API Error'))

        expect(Rails.logger).to receive(:error)
          .with("Auto-labeling failed for conversation #{conversation.id}: API Error")

        expect { service.perform }.to raise_error(StandardError, 'API Error')
      end

      it 're-raises the error for job retry mechanism' do
        classifier_service = instance_double(Labels::OpenaiClassifierService)
        allow(Labels::OpenaiClassifierService).to receive(:new).and_return(classifier_service)
        allow(classifier_service).to receive(:suggest_labels)
          .and_raise(StandardError.new('Network timeout'))
        allow(Rails.logger).to receive(:error)

        expect { service.perform }.to raise_error(StandardError, 'Network timeout')
      end
    end
  end
end
