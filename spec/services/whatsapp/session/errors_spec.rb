require 'rails_helper'

RSpec.describe Whatsapp::Session::Errors do
  # Resolved inside the example, never captured from `described_class`. A reload between
  # loading this file and running it replaces the module object, and RSpec keeps holding
  # the old one, whose child classes are no longer the ones the legacy errors inherit
  # from: `be_a` then fails against a class that looks identical. Referencing the
  # constant here re-resolves it.
  let(:errors) { Whatsapp::Session::Errors } # rubocop:disable RSpec/DescribedClass

  it 'is what the legacy providers raise, so callers rescue a single namespace' do
    expect(Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError.new).to be_a(errors::ProviderUnavailable)
    expect(Whatsapp::Providers::WhatsappZapiService::ProviderUnavailableError.new).to be_a(errors::ProviderUnavailable)
    expect(Whatsapp::Providers::WhatsappBaileysService::GroupParticipantNotAllowedError.new)
      .to be_a(errors::GroupParticipantNotAllowed)
    expect(Whatsapp::Providers::WhatsappBaileysService::MessageAlreadyProcessingError.new)
      .to be_a(errors::MessageAlreadyProcessing)
  end

  it 'treats a connection that is not usable right now as unavailable' do
    expect(errors::NotConnected.new).to be_a(errors::ProviderUnavailable)
    expect(errors::Quarantined.new).to be_a(errors::ProviderUnavailable)
    expect(errors::ClientOutdated.new).to be_a(errors::ProviderUnavailable)
  end

  describe '.build' do
    it 'maps a wire code back to its class' do
      expect(errors.build('media_too_large')).to be_a(errors::MediaTooLarge)
      expect(errors.build('not_connected', 'session is down')).to have_attributes(message: 'session is down')
    end

    it 'degrades an unknown code instead of failing the consumer' do
      expect(errors.build('teleportation_failed')).to be_a(errors::Internal)
    end

    # The connector's word for a teardown that ran out of time while the socket was being
    # dialled: nothing reached WhatsApp, so the same command again does the whole thing.
    # Degraded to Internal it read as a failure of the connector itself.
    it 'maps a teardown the connector never attempted to a class of its own' do
      error = errors.build('not_attempted', 'socket busy dialling')

      expect(error).to be_a(errors::NotAttempted)
      expect(error).to have_attributes(code: 'not_attempted', message: 'socket busy dialling', retryable?: true)
    end
  end

  # The catalogue against the vendored contract, rather than against itself. Every code the
  # connector can send is either mapped or named in UNMAPPED_WIRE_CODES, so a code the next
  # contract adds turns this red instead of arriving as a silent Internal, which is how
  # `not_attempted` went unmapped while this file stayed green.
  describe 'the codes the contract can send' do
    let(:wire_codes) do
      schema = Rails.root.join('spec/fixtures/whatsapp/session/contract/schema/protocol.schema.json')
      JSON.parse(schema.read).dig('definitions', 'error_code', 'enum')
    end

    it 'finds the enum it checks against' do
      # Vacuity guard: a schema that moved the enum would leave the sweep passing over nothing.
      expect(wire_codes).to include('internal', 'not_attempted')
    end

    it 'maps every one of them, or says why it does not' do
      unaccounted = wire_codes - errors::BY_CODE.keys - errors::UNMAPPED_WIRE_CODES
      expect(unaccounted).to be_empty,
                             "the contract can send #{unaccounted.inspect} and the catalogue neither maps it nor " \
                             'lists it in UNMAPPED_WIRE_CODES, so it arrives as Internal without anybody deciding that'
    end

    it 'lists as unmapped only codes the contract has and the catalogue does not map' do
      expect(errors::UNMAPPED_WIRE_CODES - wire_codes).to be_empty
      expect(errors::UNMAPPED_WIRE_CODES & errors::BY_CODE.keys).to be_empty
    end
  end

  it 'exposes the wire code of each class' do
    expect(errors::RateLimited.new.code).to eq('rate_limited')
    expect(errors::NotSupported.new.code).to eq('unsupported')
  end

  # Whether the same command asked again could answer differently. A lost pairing cannot:
  # it comes back only when somebody scans the QR (#855).
  {
    Whatsapp::Session::Errors::NotPaired => false,
    Whatsapp::Session::Errors::NotConnected => true,
    Whatsapp::Session::Errors::SessionNotFound => true
  }.each do |error, retryable|
    it "says #{error.name.demodulize} is #{'not ' unless retryable}worth retrying" do
      expect(error.new.retryable?).to be(retryable)
    end
  end
end
