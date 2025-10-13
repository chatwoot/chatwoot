require 'rails_helper'

RSpec.describe Companies::BusinessEmailDetectorService, type: :service do
  let(:service) { described_class.new(email) }

  describe '#perform' do
    context 'when email is from a business domain' do
      let(:email) { 'user@acme.com' }
      let(:valid_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable_domain?: false) }

      it 'returns true' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect(service.perform).to be(true)
      end
    end

    context 'when email is from gmail' do
      let(:email) { 'user@gmail.com' }
      let(:valid_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable_domain?: false) }

      it 'returns false' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect(service.perform).to be(false)
      end
    end

    context 'when email is from Brazilian free provider' do
      let(:email) { 'user@uol.com.br' }
      let(:valid_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable_domain?: false) }

      it 'returns false' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect(service.perform).to be(false)
      end
    end

    context 'when email is disposable' do
      let(:email) { 'user@mailinator.com' }
      let(:disposable_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable_domain?: true) }

      it 'returns false' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(disposable_email_address)
        expect(service.perform).to be(false)
      end
    end

    context 'when email is invalid format' do
      let(:email) { 'invalid-email' }
      let(:invalid_email_address) { instance_double(ValidEmail2::Address, valid?: false) }

      it 'returns false' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(invalid_email_address)
        expect(service.perform).to be(false)
      end
    end

    context 'when email is nil' do
      let(:email) { nil }

      it 'remains false' do
        expect(service.perform).to be(false)
      end
    end

    context 'when email is empty string' do
      let(:email) { '' }

      it 'returns false' do
        expect(service.perform).to be(false)
      end
    end

    context 'when email domain is uppercase' do
      let(:email) { 'user@GMAIL.COM' }
      let(:valid_email_address) { instance_double(ValidEmail2::Address, valid?: true, disposable_domain?: false) }

      it 'returns false (case insensitive)' do
        allow(ValidEmail2::Address).to receive(:new).with(email).and_return(valid_email_address)
        expect(service.perform).to be(false)
      end
    end
  end
end
