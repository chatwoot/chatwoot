require 'rails_helper'

# The wire contract is owned by fazer-ai/whatsapp-connector and vendored here. These
# examples are what keeps the Ruby model and that contract from drifting apart: every
# golden frame must validate against the schema AND survive a round trip through the
# canonical model, and every type the model knows must have a golden frame.
RSpec.describe Whatsapp::SessionContract do
  # A frame the model parsed and re-serialized must carry every field the golden frame
  # had. It may carry more: a member with a declared default is materialized on the way
  # out even when the producer left it implicit.
  def preserves?(expected, actual)
    return expected.all? { |key, value| value.nil? || preserves?(value, actual[key]) } if expected.is_a?(Hash) && actual.is_a?(Hash)
    return preserves_list?(expected, actual) if expected.is_a?(Array)

    expected == actual
  end

  def preserves_list?(expected, actual)
    return false unless actual.is_a?(Array) && expected.size == actual.size

    expected.each_with_index.all? { |item, index| preserves?(item, actual[index]) }
  end

  it 'is vendored at the protocol version the code implements' do
    expect(described_class.protocol_version).to eq(Whatsapp::Session::PROTOCOL_VERSION)
  end

  # `drifted?` above only compares the copy against the checksum it was vendored with, so it
  # catches a local edit and nothing else. Saying what is different from another checkout is
  # what lets the weekly run name the event the connector added while this side was not
  # looking, which otherwise reaches the dispatcher as Unknown and is logged as an unknown
  # payload -- the same shape as a type we deliberately ignore.
  describe '.diff' do
    let(:other) { Pathname.new(Dir.mktmpdir) }

    before { FileUtils.cp_r("#{described_class.root}/.", other) }

    after { FileUtils.rm_rf(other) }

    it 'finds nothing between two copies of the same contract' do
      expect(described_class.diff(other).values.flatten).to be_empty
    end

    it 'names a file the other copy has and this one does not' do
      other.join('fixtures/events/session_something_the_connector_added.json').write('{}')

      expect(described_class.diff(other))
        .to include(behind: ['fixtures/events/session_something_the_connector_added.json'], stale: [], ahead: [])
    end

    it 'names a file whose contents moved on' do
      other.join('PROTOCOL_VERSION').write('99')

      expect(described_class.diff(other)).to include(stale: ['PROTOCOL_VERSION'], behind: [], ahead: [])
    end

    # CONTRACT_REF records the result of hashing the contract and the connector's README
    # describes the directory to whoever reads it there. Counting either would report drift
    # on every comparison, for ever.
    it 'ignores the files that are not part of the contract' do
      other.join('README.md').write('the contract lives here')
      other.join('CONTRACT_REF').write('repo=someone/else\nref=deadbeef\nchecksum=nonsense\n')

      expect(described_class.diff(other).values.flatten).to be_empty
    end
  end

  it 'has not been edited locally' do
    expect(described_class.drifted?).to be(false),
                                        'the vendored contract no longer matches CONTRACT_REF; run rails whatsapp:contract:sync'
  end

  describe 'events' do
    it 'has a golden frame for every known type' do
      covered = described_class.fixtures('events').map { |path| JSON.parse(File.read(path))['type'] }.uniq

      expect(Whatsapp::Session::Model::Events::TYPES - covered).to be_empty
    end

    it 'validates every golden frame against the schema' do
      invalid = described_class.fixtures('events').reject do |path|
        described_class.event_validator.valid?(JSON.parse(File.read(path)))
      end

      expect(invalid.map { |path| File.basename(path) }).to be_empty
    end

    it 'round-trips every golden frame through the canonical model' do
      mismatched = described_class.fixtures('events').reject do |path|
        frame = JSON.parse(File.read(path))
        event = Whatsapp::Session::Model::Event.from_frame(frame)

        preserves?(frame, event.to_frame) && Whatsapp::Session::Model::Event.from_frame(event.to_frame) == event
      end

      expect(mismatched.map { |path| File.basename(path) }).to be_empty
    end

    it 'builds a typed payload for every golden frame' do
      untyped = described_class.fixtures('events').reject do |path|
        Whatsapp::Session::Model::Event.from_frame(JSON.parse(File.read(path))).known?
      end

      expect(untyped.map { |path| File.basename(path) }).to be_empty
    end
  end

  describe 'commands' do
    it 'has a golden frame for every known type' do
      covered = described_class.fixtures('commands').map { |path| JSON.parse(File.read(path))['type'] }.uniq

      expect(Whatsapp::Session::Model::Commands::TYPES - covered).to be_empty
    end

    it 'validates every golden frame against the schema' do
      invalid = described_class.fixtures('commands').reject do |path|
        described_class.command_validator.valid?(JSON.parse(File.read(path)))
      end

      expect(invalid.map { |path| File.basename(path) }).to be_empty
    end

    it 'round-trips every golden frame through the canonical model' do
      mismatched = described_class.fixtures('commands').reject do |path|
        frame = JSON.parse(File.read(path))
        command = Whatsapp::Session::Model::Command.from_frame(frame)

        preserves?(frame, command.to_frame) && Whatsapp::Session::Model::Command.from_frame(command.to_frame) == command
      end

      expect(mismatched.map { |path| File.basename(path) }).to be_empty
    end
  end

  # RPC_TYPES is a hand-kept list, and the contract already says which commands are one:
  # a golden frame carries `reply_to` and a `deadline` exactly when its caller waits for a
  # result. Kept apart, a command synced in as an RPC stays fire-and-forget here, and the
  # caller that should have awaited a result simply never asks for one.
  it 'calls a command an RPC exactly when its golden frame waits for a reply' do
    disagreeing = described_class.fixtures('commands').filter_map do |path|
      frame = JSON.parse(File.read(path))
      awaited = frame['reply_to'].present?
      next if awaited == Whatsapp::Session::Model::Commands.rpc?(frame['type'])

      "#{frame['type']} (frame #{awaited ? 'waits' : 'does not wait'}, RPC_TYPES says #{!awaited})"
    end

    expect(disagreeing).to be_empty
  end

  describe 'forward compatibility' do
    it 'keeps an unknown event type instead of failing' do
      frame = described_class.fixture('events', 'message_received_text').merge('type' => 'message.teleported')

      event = Whatsapp::Session::Model::Event.from_frame(frame)

      expect(event.known?).to be(false)
      expect(event.type).to eq('message.teleported')
    end

    it 'ignores unknown payload fields' do
      frame = described_class.fixture('events', 'session_state_open')
      frame['payload']['satellite_uplink'] = true

      expect(Whatsapp::Session::Model::Event.from_frame(frame).payload.state).to eq('open')
    end

    it 'refuses an unknown command type' do
      frame = described_class.fixture('commands', 'message_send_text').merge('type' => 'message.teleport')

      expect { Whatsapp::Session::Model::Command.from_frame(frame) }
        .to raise_error(Whatsapp::Session::Errors::InvalidPayload)
    end
  end
end
