require 'rails_helper'

describe Messages::StatusUpdateService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) { create(:message, conversation: conversation, account: account) }

  describe '#perform' do
    context 'when status is valid' do
      it 'updates the status of the message' do
        service = described_class.new(message, 'delivered')
        service.perform
        expect(message.reload.status).to eq('delivered')
      end

      it 'clears external_error when status is not failed' do
        message.update!(status: 'failed', external_error: 'previous error')
        service = described_class.new(message, 'delivered')
        service.perform
        expect(message.reload.status).to eq('delivered')
        expect(message.reload.external_error).to be_nil
      end

      it 'updates external_error when status is failed' do
        service = described_class.new(message, 'failed', 'some error')
        service.perform
        expect(message.reload.status).to eq('failed')
        expect(message.reload.external_error).to eq('some error')
      end
    end

    context 'when status is invalid' do
      it 'returns false for invalid status' do
        service = described_class.new(message, 'invalid_status')
        expect(service.perform).to be false
      end

      it 'prevents transition from read to delivered' do
        message.update!(status: 'read')
        service = described_class.new(message, 'delivered')
        expect(service.perform).to be false
        expect(message.reload.status).to eq('read')
      end

      it 'prevents transition from delivered to sent (out-of-order webhook)' do
        message.update!(status: 'delivered')
        service = described_class.new(message, 'sent')
        expect(service.perform).to be false
        expect(message.reload.status).to eq('delivered')
      end

      it 'prevents transition from read to sent (out-of-order webhook)' do
        message.update!(status: 'read')
        service = described_class.new(message, 'sent')
        expect(service.perform).to be false
        expect(message.reload.status).to eq('read')
      end
    end

    context 'when transitioning to failed' do
      it 'allows transition from sent to failed' do
        message.update!(status: 'sent')
        service = described_class.new(message, 'failed', 'delivery error')
        expect(service.perform).to be_truthy
        expect(message.reload.status).to eq('failed')
      end

      it 'allows transition from delivered to failed' do
        message.update!(status: 'delivered')
        service = described_class.new(message, 'failed', 'late failure')
        expect(service.perform).to be_truthy
        expect(message.reload.status).to eq('failed')
      end

      it 'allows transition from read to failed' do
        message.update!(status: 'read')
        service = described_class.new(message, 'failed', 'late failure')
        expect(service.perform).to be_truthy
        expect(message.reload.status).to eq('failed')
      end

      it 'preserves existing external_error when new error is nil' do
        message.update!(status: 'failed', external_error: 'original error')
        service = described_class.new(message, 'failed', nil)
        service.perform
        expect(message.reload.external_error).to eq('original error')
      end

      it 'overwrites external_error when new error is provided' do
        message.update!(status: 'failed', external_error: 'original error')
        service = described_class.new(message, 'failed', 'new error')
        service.perform
        expect(message.reload.external_error).to eq('new error')
      end
    end

    context 'when retrying failed messages' do
      it 'allows transition from failed to sent (retry flow)' do
        message.update!(status: 'failed', external_error: 'previous error')
        service = described_class.new(message, 'sent')
        expect(service.perform).to be_truthy
        expect(message.reload.status).to eq('sent')
        expect(message.reload.external_error).to be_nil
      end

      it 'allows transition from failed to delivered (retry success callback)' do
        message.update!(status: 'failed')
        service = described_class.new(message, 'delivered')
        expect(service.perform).to be_truthy
        expect(message.reload.status).to eq('delivered')
      end
    end

    context 'when current status is nil (legacy data)' do
      it 'allows transition to any valid status' do
        message.update_column(:status, nil) # rubocop:disable Rails/SkipsModelValidations
        service = described_class.new(message, 'delivered')
        expect(service.perform).to be_truthy
        expect(message.reload.status).to eq('delivered')
      end
    end
  end
end
